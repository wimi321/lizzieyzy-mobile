"""TLS-only WebSocket to KataGo Analysis JSONL bridge.

The bridge deliberately has a small command surface: regular KataGo analysis
objects and the official ``terminate`` action. It never logs WebSocket payloads,
authorization headers, or KataGo stdout/stderr.
"""

from __future__ import annotations

import argparse
import asyncio
import contextlib
import hashlib
import hmac
import json
import logging
import math
import os
import re
import signal
import ssl
import stat
import sys
from collections.abc import AsyncIterator, Mapping, Sequence
from dataclasses import dataclass
from http import HTTPStatus
from pathlib import Path
from typing import Any, Protocol, cast

from websockets.asyncio.server import ServerConnection, serve
from websockets.exceptions import ConnectionClosed

from .errors import BridgeConfigurationError
from .trust import load_runtime_trust, stage_runtime_artifacts

LOGGER = logging.getLogger("katago_bridge")
_SAFE_REQUEST_ID = re.compile(r"^[A-Za-z0-9._:-]{1,128}$")
_SAFE_TOKEN = re.compile(rb"^[A-Za-z0-9._~+/=-]{32,4096}$")
_SAFE_ENVIRONMENT_NAME = re.compile(r"^[A-Za-z_][A-Za-z0-9_]{0,127}$")
_SENSITIVE_CHILD_ENVIRONMENT = re.compile(
    r"(?:TOKEN|SECRET|PASSWORD|PASSWD|AUTH|CREDENTIAL|COOKIE|API_KEY)", re.I
)
_AUTH_ENVIRONMENT_VARIABLE = "LIZZIEYZY_BRIDGE_TOKEN"
_BOARD_DIMENSIONS = frozenset({9, 13, 19})
_RULES = frozenset(
    {"chinese", "japanese", "korean", "aga", "new-zealand", "tromp-taylor"}
)
_GTP_COLUMNS = "ABCDEFGHJKLMNOPQRSTUVWXYZ"
_MAX_MOVES = 999
_MAX_VISITS = 20_000
_MAX_PV_LENGTH = 128
_MAX_ACTIVE_ANALYSES = 4
_ANALYSIS_REQUEST_FIELDS = frozenset(
    {
        "id",
        "initialStones",
        "initialPlayer",
        "moves",
        "rules",
        "komi",
        "boardXSize",
        "boardYSize",
        "analyzeTurns",
        "maxVisits",
        "analysisPVLen",
        "includeOwnership",
        "includePolicy",
    }
)
_TERMINATE_REQUEST_FIELDS = frozenset({"id", "action", "terminateId"})


class BridgeProtocolError(ValueError):
    """Raised for a client request outside the supported JSONL protocol."""


class BridgeBudgetExceeded(BridgeProtocolError):
    """Raised when a configured resource budget is exceeded."""


class EngineUnavailable(RuntimeError):
    """Raised when the isolated KataGo process cannot continue."""


@dataclass(frozen=True, slots=True)
class _ValidatedClientRequest:
    request_id: str
    analyze_turns: tuple[int, ...] = ()
    terminate_id: str | None = None


class WebSocketPeer(Protocol):
    def __aiter__(self) -> AsyncIterator[str | bytes]: ...

    async def send(self, message: str) -> None: ...

    async def close(self, code: int = 1000, reason: str = "") -> None: ...


@dataclass(frozen=True, slots=True)
class BridgeBudgets:
    """Hard resource ceilings applied independently to every connection."""

    max_connections: int = 1
    max_message_bytes: int = 1024 * 1024
    max_frame_bytes: int = 1024 * 1024
    max_lines_per_message: int = 16
    max_line_bytes: int = 1024 * 1024
    max_json_depth: int = 32
    max_json_structural_tokens: int = 250_000
    max_requests_per_connection: int = 4096
    process_start_timeout_seconds: float = 20.0
    process_timeout_seconds: float = 50.0 * 60.0
    process_shutdown_timeout_seconds: float = 5.0

    def __post_init__(self) -> None:
        integer_values = {
            "max_connections": self.max_connections,
            "max_message_bytes": self.max_message_bytes,
            "max_frame_bytes": self.max_frame_bytes,
            "max_lines_per_message": self.max_lines_per_message,
            "max_line_bytes": self.max_line_bytes,
            "max_json_depth": self.max_json_depth,
            "max_json_structural_tokens": self.max_json_structural_tokens,
            "max_requests_per_connection": self.max_requests_per_connection,
        }
        for name, value in integer_values.items():
            if isinstance(value, bool) or value <= 0:
                raise BridgeConfigurationError(f"{name} must be a positive integer")
        absolute_integer_ceilings = {
            "max_connections": 8,
            "max_message_bytes": 8 * 1024 * 1024,
            "max_frame_bytes": 8 * 1024 * 1024,
            "max_lines_per_message": 1024,
            "max_line_bytes": 8 * 1024 * 1024,
            "max_json_depth": 64,
            "max_json_structural_tokens": 1_000_000,
            "max_requests_per_connection": 65_536,
        }
        for name, ceiling in absolute_integer_ceilings.items():
            if integer_values[name] > ceiling:
                raise BridgeConfigurationError(
                    f"{name} exceeds its hard safety ceiling"
                )
        timeout_values = {
            "process_start_timeout_seconds": self.process_start_timeout_seconds,
            "process_timeout_seconds": self.process_timeout_seconds,
            "process_shutdown_timeout_seconds": self.process_shutdown_timeout_seconds,
        }
        for name, value in timeout_values.items():
            if not math.isfinite(value) or value <= 0:
                raise BridgeConfigurationError(f"{name} must be positive and finite")
        absolute_timeout_ceilings = {
            "process_start_timeout_seconds": 120.0,
            "process_timeout_seconds": 24.0 * 60.0 * 60.0,
            "process_shutdown_timeout_seconds": 30.0,
        }
        for name, ceiling in absolute_timeout_ceilings.items():
            if timeout_values[name] > ceiling:
                raise BridgeConfigurationError(
                    f"{name} exceeds its hard safety ceiling"
                )
        if self.max_frame_bytes > self.max_message_bytes:
            raise BridgeConfigurationError(
                "max_frame_bytes cannot exceed max_message_bytes"
            )
        if self.max_line_bytes > self.max_message_bytes:
            raise BridgeConfigurationError(
                "max_line_bytes cannot exceed max_message_bytes"
            )
        if self.max_line_bytes > self.max_frame_bytes:
            raise BridgeConfigurationError(
                "max_line_bytes cannot exceed max_frame_bytes"
            )


@dataclass(frozen=True, slots=True)
class EngineCommand:
    """Validated KataGo executable and model files; never a shell command."""

    executable: Path
    config: Path
    model: Path
    human_model: Path | None = None

    @classmethod
    def validated(
        cls,
        *,
        executable: str | os.PathLike[str],
        config: str | os.PathLike[str],
        model: str | os.PathLike[str],
        human_model: str | os.PathLike[str] | None = None,
    ) -> EngineCommand:
        engine_path = _regular_file(executable, "KataGo executable")
        if not os.access(engine_path, os.X_OK):
            raise BridgeConfigurationError("KataGo executable is not executable")
        config_path = _regular_file(config, "KataGo analysis config")
        model_path = _regular_file(model, "KataGo analysis model")
        human_path = (
            _regular_file(human_model, "KataGo HumanSL model")
            if human_model is not None
            else None
        )
        return cls(engine_path, config_path, model_path, human_path)

    @property
    def argv(self) -> tuple[str, ...]:
        arguments = [
            str(self.executable),
            "analysis",
            "-config",
            str(self.config),
            "-model",
            str(self.model),
        ]
        if self.human_model is not None:
            arguments.extend(("-human-model", str(self.human_model)))
        return tuple(arguments)


@dataclass(frozen=True, slots=True)
class BearerAuthenticator:
    """Stores only a SHA-256 digest and compares fixed-size values."""

    _token_digest: bytes

    @classmethod
    def from_token(cls, token: str | bytes) -> BearerAuthenticator:
        try:
            raw = token.encode("ascii") if isinstance(token, str) else bytes(token)
        except (UnicodeEncodeError, TypeError, ValueError) as error:
            raise BridgeConfigurationError("Bearer token must be ASCII") from error
        if _SAFE_TOKEN.fullmatch(raw) is None:
            raise BridgeConfigurationError(
                "Bearer token must be 32-4096 visible bearer-token characters"
            )
        return cls(hashlib.sha256(raw).digest())

    def accepts(self, authorization_values: Sequence[str]) -> bool:
        candidate = b""
        well_formed = False
        if len(authorization_values) == 1:
            value = authorization_values[0]
            if isinstance(value, str):
                scheme, separator, credential = value.partition(" ")
                if separator and scheme.casefold() == "bearer" and credential:
                    try:
                        candidate = credential.encode("ascii")
                        well_formed = _SAFE_TOKEN.fullmatch(candidate) is not None
                    except UnicodeEncodeError:
                        candidate = b""
        # Hash first so compare_digest always receives equal-length inputs.
        matches = hmac.compare_digest(
            hashlib.sha256(candidate).digest(), self._token_digest
        )
        return well_formed and matches


def load_bearer_authenticator(
    *, token_env: str = _AUTH_ENVIRONMENT_VARIABLE, token_file: Path | None = None
) -> BearerAuthenticator:
    """Load a token from one unambiguous source without retaining plain text."""

    if _SAFE_ENVIRONMENT_NAME.fullmatch(token_env) is None:
        raise BridgeConfigurationError("Token environment variable name is invalid")
    environment_token = os.environ.get(token_env)
    if token_file is not None and environment_token is not None:
        raise BridgeConfigurationError(
            "Bearer token is configured in both the environment and a file"
        )
    if token_file is not None:
        raw = _read_private_token_file(token_file)
    elif environment_token is not None:
        try:
            raw = environment_token.encode("ascii")
        except UnicodeEncodeError as error:
            raise BridgeConfigurationError("Bearer token must be ASCII") from error
    else:
        raise BridgeConfigurationError(
            f"Bearer token is missing from environment variable {token_env}"
        )
    return BearerAuthenticator.from_token(raw)


def _read_private_token_file(path: Path) -> bytes:
    if os.name != "posix":
        raise BridgeConfigurationError(
            "Token files require POSIX permission checks; use an environment variable"
        )
    flags = os.O_RDONLY
    flags |= getattr(os, "O_CLOEXEC", 0)
    flags |= getattr(os, "O_NOFOLLOW", 0)
    try:
        descriptor = os.open(path, flags)
    except OSError as error:
        raise BridgeConfigurationError(
            "Could not securely open bearer token file"
        ) from error
    try:
        metadata = os.fstat(descriptor)
        if not stat.S_ISREG(metadata.st_mode):
            raise BridgeConfigurationError("Bearer token file must be a regular file")
        if stat.S_IMODE(metadata.st_mode) != 0o600:
            raise BridgeConfigurationError("Bearer token file permissions must be 0600")
        if metadata.st_uid != os.geteuid():
            raise BridgeConfigurationError(
                "Bearer token file must be owned by this user"
            )
        raw = os.read(descriptor, 4099)
        if len(raw) > 4098 or os.read(descriptor, 1):
            raise BridgeConfigurationError("Bearer token file is too large")
    finally:
        os.close(descriptor)
    if raw.endswith(b"\r\n"):
        raw = raw[:-2]
    elif raw.endswith(b"\n"):
        raw = raw[:-1]
    if b"\r" in raw or b"\n" in raw:
        raise BridgeConfigurationError("Bearer token file contains multiple lines")
    return raw


class ConnectionLimiter:
    """Race-free global cap; rejected connections never spawn KataGo."""

    def __init__(self, maximum: int) -> None:
        if maximum <= 0:
            raise BridgeConfigurationError("maximum connections must be positive")
        self._maximum = maximum
        self._active = 0
        self._lock = asyncio.Lock()

    async def try_acquire(self) -> bool:
        async with self._lock:
            if self._active >= self._maximum:
                return False
            self._active += 1
            return True

    async def release(self) -> None:
        async with self._lock:
            if self._active <= 0:
                raise RuntimeError("connection limiter released without an owner")
            self._active -= 1


class BridgeSession:
    """One authenticated WebSocket mapped to one isolated KataGo process."""

    def __init__(
        self,
        websocket: WebSocketPeer,
        command: EngineCommand,
        budgets: BridgeBudgets,
        *,
        subprocess_environment: Mapping[str, str] | None = None,
        human_style_ranks: Sequence[str] = (),
    ) -> None:
        self._websocket = websocket
        self._command = command
        self._budgets = budgets
        self._subprocess_environment = (
            dict(subprocess_environment) if subprocess_environment is not None else None
        )
        self._request_count = 0
        self._allowed_human_profiles = frozenset(
            f"rank_{rank}" for rank in human_style_ranks
        )
        self._seen_request_ids: set[str] = set()
        self._active_analyses: dict[str, set[int]] = {}
        self.process: asyncio.subprocess.Process | None = None

    async def run(self) -> None:
        try:
            process = await asyncio.wait_for(
                self._spawn_process(),
                timeout=self._budgets.process_start_timeout_seconds,
            )
            self.process = process
            async with asyncio.timeout(self._budgets.process_timeout_seconds):
                await self._relay(process)
        except TimeoutError:
            await self._close_websocket(1011, "Analysis engine time budget exceeded")
        except BridgeBudgetExceeded:
            await self._close_websocket(1009, "Request exceeds configured budget")
        except BridgeProtocolError:
            await self._close_websocket(1008, "Unsupported analysis request")
        except ConnectionClosed:
            pass
        except (EngineUnavailable, OSError):
            await self._close_websocket(1011, "Analysis engine unavailable")
        finally:
            if self.process is not None:
                await _stop_process(
                    self.process,
                    grace_seconds=self._budgets.process_shutdown_timeout_seconds,
                )

    async def _spawn_process(self) -> asyncio.subprocess.Process:
        keyword_arguments: dict[str, Any] = {
            "stdin": asyncio.subprocess.PIPE,
            "stdout": asyncio.subprocess.PIPE,
            "stderr": asyncio.subprocess.DEVNULL,
            "env": self._subprocess_environment,
            "limit": self._budgets.max_line_bytes + 1,
        }
        if os.name == "posix":
            keyword_arguments["start_new_session"] = True
        elif os.name == "nt":
            keyword_arguments["creationflags"] = getattr(
                __import__("subprocess"), "CREATE_NEW_PROCESS_GROUP", 0
            )
        return await asyncio.create_subprocess_exec(
            *self._command.argv, **keyword_arguments
        )

    async def _relay(self, process: asyncio.subprocess.Process) -> None:
        if process.stdin is None or process.stdout is None:
            raise EngineUnavailable("KataGo pipes are unavailable")
        client_task = asyncio.create_task(self._client_to_engine(process.stdin))
        engine_task = asyncio.create_task(self._engine_to_client(process.stdout))
        process_task = asyncio.create_task(process.wait())
        tasks = {client_task, engine_task, process_task}
        try:
            done, _ = await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
            if client_task in done:
                await client_task
                return
            if engine_task in done:
                await engine_task
                raise EngineUnavailable("KataGo stdout closed")
            if process_task in done:
                await process_task
                raise EngineUnavailable("KataGo process exited")
        finally:
            for task in tasks:
                if not task.done():
                    task.cancel()
            await asyncio.gather(*tasks, return_exceptions=True)

    async def _client_to_engine(self, writer: asyncio.StreamWriter) -> None:
        async for message in self._websocket:
            for line in _validated_message_lines(message, self._budgets):
                self._request_count += 1
                if self._request_count > self._budgets.max_requests_per_connection:
                    raise BridgeBudgetExceeded("request-count budget exceeded")
                request = _decode_json_object(line, self._budgets)
                validated = _validate_request(
                    request,
                    allowed_human_profiles=self._allowed_human_profiles,
                )
                if validated.request_id in self._seen_request_ids:
                    raise BridgeProtocolError("request ids must be unique")
                if validated.terminate_id is not None:
                    if validated.terminate_id not in self._active_analyses:
                        raise BridgeProtocolError(
                            "terminateId does not belong to this connection"
                        )
                    self._active_analyses.pop(validated.terminate_id)
                else:
                    if len(self._active_analyses) >= _MAX_ACTIVE_ANALYSES:
                        raise BridgeBudgetExceeded(
                            "concurrent analysis budget exceeded"
                        )
                    self._active_analyses[validated.request_id] = set(
                        validated.analyze_turns
                    )
                self._seen_request_ids.add(validated.request_id)
                writer.write(line.encode("utf-8") + b"\n")
                await writer.drain()

    async def _engine_to_client(self, reader: asyncio.StreamReader) -> None:
        while True:
            try:
                raw_line = await reader.readline()
            except (ValueError, asyncio.LimitOverrunError) as error:
                raise BridgeBudgetExceeded("KataGo line budget exceeded") from error
            if not raw_line:
                return
            if len(raw_line) > self._budgets.max_line_bytes + 1:
                raise BridgeBudgetExceeded("KataGo line budget exceeded")
            if raw_line.endswith(b"\n"):
                raw_line = raw_line[:-1]
            if raw_line.endswith(b"\r"):
                raw_line = raw_line[:-1]
            if len(raw_line) > self._budgets.max_line_bytes:
                raise BridgeBudgetExceeded("KataGo line budget exceeded")
            try:
                line = raw_line.decode("utf-8", errors="strict")
            except UnicodeDecodeError as error:
                raise BridgeProtocolError("KataGo output is not UTF-8") from error
            response = _decode_json_object(line, self._budgets)
            self._observe_engine_response(response)
            await self._websocket.send(line)

    def _observe_engine_response(self, response: Mapping[str, Any]) -> None:
        request_id = response.get("id")
        if not isinstance(request_id, str):
            return
        pending_turns = self._active_analyses.get(request_id)
        if pending_turns is None:
            return
        if "error" in response:
            self._active_analyses.pop(request_id, None)
            return
        if response.get("isDuringSearch") is True or "warning" in response:
            return
        turn_number = response.get("turnNumber")
        if (
            isinstance(turn_number, int)
            and not isinstance(turn_number, bool)
            and turn_number in pending_turns
        ):
            pending_turns.remove(turn_number)
            if not pending_turns:
                self._active_analyses.pop(request_id, None)

    async def _close_websocket(self, code: int, reason: str) -> None:
        with contextlib.suppress(ConnectionClosed, OSError, RuntimeError):
            await self._websocket.close(code=code, reason=reason)


def _validated_message_lines(message: str | bytes, budgets: BridgeBudgets) -> list[str]:
    if isinstance(message, bytes):
        if len(message) > budgets.max_message_bytes:
            raise BridgeBudgetExceeded("message budget exceeded")
        try:
            text = message.decode("utf-8", errors="strict")
        except UnicodeDecodeError as error:
            raise BridgeProtocolError("request is not UTF-8") from error
    elif isinstance(message, str):
        try:
            encoded = message.encode("utf-8")
        except UnicodeEncodeError as error:
            raise BridgeProtocolError("request contains invalid Unicode") from error
        if len(encoded) > budgets.max_message_bytes:
            raise BridgeBudgetExceeded("message budget exceeded")
        text = message
    else:
        raise BridgeProtocolError("WebSocket request must be text or bytes")

    raw_lines = text.split("\n")
    if text.endswith("\n"):
        raw_lines.pop()
    if len(raw_lines) > budgets.max_lines_per_message:
        raise BridgeBudgetExceeded("line-count budget exceeded")
    lines: list[str] = []
    for raw_line in raw_lines:
        line = raw_line[:-1] if raw_line.endswith("\r") else raw_line
        try:
            size = len(line.encode("utf-8"))
        except UnicodeEncodeError as error:
            raise BridgeProtocolError("request contains invalid Unicode") from error
        if size > budgets.max_line_bytes:
            raise BridgeBudgetExceeded("line-size budget exceeded")
        if line.strip():
            lines.append(line)
    return lines


def _decode_json_object(line: str, budgets: BridgeBudgets) -> dict[str, Any]:
    _validate_json_complexity(line, budgets)

    def reject_constant(value: str) -> None:
        raise BridgeProtocolError(f"non-finite JSON number {value} is forbidden")

    def unique_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
        result: dict[str, Any] = {}
        for key, value in pairs:
            if key in result:
                raise BridgeProtocolError("duplicate JSON object key")
            result[key] = value
        return result

    try:
        decoded = json.loads(
            line,
            object_pairs_hook=unique_object,
            parse_constant=reject_constant,
        )
    except BridgeProtocolError:
        raise
    except (json.JSONDecodeError, UnicodeError, ValueError) as error:
        raise BridgeProtocolError("malformed JSON request") from error
    if not isinstance(decoded, dict):
        raise BridgeProtocolError("JSONL entry must be an object")
    return cast(dict[str, Any], decoded)


def _validate_json_complexity(line: str, budgets: BridgeBudgets) -> None:
    depth = 0
    tokens = 0
    in_string = False
    escaped = False
    for character in line:
        if in_string:
            if escaped:
                escaped = False
            elif character == "\\":
                escaped = True
            elif character == '"':
                in_string = False
            continue
        if character == '"':
            in_string = True
        elif character in "[{":
            depth += 1
            tokens += 1
            if depth > budgets.max_json_depth:
                raise BridgeBudgetExceeded("JSON depth budget exceeded")
        elif character in "]}":
            depth -= 1
            tokens += 1
            if depth < 0:
                raise BridgeProtocolError("JSON containers are unbalanced")
        elif character in ",:":
            tokens += 1
        if tokens > budgets.max_json_structural_tokens:
            raise BridgeBudgetExceeded("JSON structural-token budget exceeded")
    if depth != 0 or in_string or escaped:
        raise BridgeProtocolError("JSON entry is incomplete")


def _validate_request(
    request: Mapping[str, Any], *, allowed_human_profiles: frozenset[str]
) -> _ValidatedClientRequest:
    request_id = request.get("id")
    if (
        not isinstance(request_id, str)
        or _SAFE_REQUEST_ID.fullmatch(request_id) is None
    ):
        raise BridgeProtocolError("request id is missing or unsafe")
    if "action" in request:
        if set(request) != _TERMINATE_REQUEST_FIELDS:
            raise BridgeProtocolError("terminate request fields are invalid")
        if request["action"] != "terminate":
            raise BridgeProtocolError("only the terminate action is supported")
        terminate_id = request.get("terminateId")
        if (
            not isinstance(terminate_id, str)
            or _SAFE_REQUEST_ID.fullmatch(terminate_id) is None
        ):
            raise BridgeProtocolError("terminateId is missing or unsafe")
        if terminate_id == request_id:
            raise BridgeProtocolError("terminate request cannot target itself")
        return _ValidatedClientRequest(
            request_id=request_id,
            terminate_id=terminate_id,
        )

    optional_fields = {"overrideSettings"} if "overrideSettings" in request else set()
    if set(request) != _ANALYSIS_REQUEST_FIELDS | optional_fields:
        raise BridgeProtocolError("analysis request fields are invalid")
    board_x = _required_int(request["boardXSize"], "boardXSize")
    board_y = _required_int(request["boardYSize"], "boardYSize")
    if board_x != board_y or board_x not in _BOARD_DIMENSIONS:
        raise BridgeProtocolError("board size must be square and 9, 13, or 19")
    initial_player = request["initialPlayer"]
    if initial_player not in {"B", "W"}:
        raise BridgeProtocolError("initialPlayer must be B or W")

    initial_stones = request["initialStones"]
    if not isinstance(initial_stones, list):
        raise BridgeProtocolError("initialStones must be an array")
    if len(initial_stones) > board_x * board_x:
        raise BridgeBudgetExceeded("initialStones exceeds the board-area budget")
    occupied: set[str] = set()
    for stone in initial_stones:
        color, location = _stone_or_move(stone, board_x, allow_pass=False)
        if color not in {"B", "W"} or location in occupied:
            raise BridgeProtocolError(
                "initialStones contains invalid or duplicate points"
            )
        occupied.add(location)

    moves = request["moves"]
    if not isinstance(moves, list):
        raise BridgeProtocolError("moves must be an array")
    if len(moves) > _MAX_MOVES:
        raise BridgeBudgetExceeded("moves exceeds the supported position budget")
    for move in moves:
        _stone_or_move(move, board_x, allow_pass=True)

    rules = request["rules"]
    if not isinstance(rules, str) or rules not in _RULES:
        raise BridgeProtocolError("rules is unsupported")
    komi = request["komi"]
    if isinstance(komi, bool) or not isinstance(komi, (int, float)):
        raise BridgeProtocolError("komi must be finite and within -150 to 150")
    try:
        komi_value = float(komi)
    except OverflowError as error:
        raise BridgeProtocolError(
            "komi must be finite and within -150 to 150"
        ) from error
    if not math.isfinite(komi_value) or not -150.0 <= komi_value <= 150.0:
        raise BridgeProtocolError("komi must be finite and within -150 to 150")
    analyze_turns = request["analyzeTurns"]
    expected_turns = list(range(len(moves) + 1))
    if (
        not isinstance(analyze_turns, list)
        or any(
            isinstance(turn, bool) or not isinstance(turn, int)
            for turn in analyze_turns
        )
        or analyze_turns != expected_turns
    ):
        raise BridgeProtocolError(
            "analyzeTurns must cover every submitted position once"
        )
    max_visits = _required_int(request["maxVisits"], "maxVisits")
    if not 1 <= max_visits <= _MAX_VISITS:
        raise BridgeBudgetExceeded("maxVisits exceeds the App analysis budget")
    pv_length = _required_int(request["analysisPVLen"], "analysisPVLen")
    if not 1 <= pv_length <= _MAX_PV_LENGTH:
        raise BridgeBudgetExceeded("analysisPVLen exceeds the App analysis budget")
    if not isinstance(request["includeOwnership"], bool):
        raise BridgeProtocolError("includeOwnership must be a boolean")
    if request["includePolicy"] is not True:
        raise BridgeProtocolError("includePolicy must be true")
    if "overrideSettings" in request:
        override = request["overrideSettings"]
        if not isinstance(override, dict) or set(override) != {
            "humanSLProfile",
            "ignorePreRootHistory",
        }:
            raise BridgeProtocolError("overrideSettings fields are invalid")
        profile = override["humanSLProfile"]
        if not isinstance(profile, str) or profile not in allowed_human_profiles:
            raise BridgeProtocolError("humanSLProfile is not declared by the manifest")
        if override["ignorePreRootHistory"] is not False:
            raise BridgeProtocolError("ignorePreRootHistory must be false")
    return _ValidatedClientRequest(
        request_id=request_id,
        analyze_turns=tuple(expected_turns),
    )


def _required_int(value: Any, field: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        raise BridgeProtocolError(f"{field} must be an integer")
    return value


def _stone_or_move(value: Any, board_size: int, *, allow_pass: bool) -> tuple[str, str]:
    if not isinstance(value, list) or len(value) != 2:
        raise BridgeProtocolError("stones and moves must be two-item arrays")
    color, location = value
    if color not in {"B", "W"} or not isinstance(location, str):
        raise BridgeProtocolError("stone or move color/location is invalid")
    if location == "pass":
        if allow_pass:
            return color, location
        raise BridgeProtocolError("initial stones cannot pass")
    match = re.fullmatch(r"([A-Z])([1-9][0-9]?)", location)
    if match is None:
        raise BridgeProtocolError("stone or move coordinate is invalid")
    column, row_text = match.groups()
    if column not in _GTP_COLUMNS[:board_size] or not 1 <= int(row_text) <= board_size:
        raise BridgeProtocolError("stone or move coordinate is outside the board")
    return color, location


async def _stop_process(
    process: asyncio.subprocess.Process, *, grace_seconds: float
) -> None:
    if process.stdin is not None:
        process.stdin.close()
        with contextlib.suppress(
            BrokenPipeError, ConnectionResetError, RuntimeError, TimeoutError
        ):
            async with asyncio.timeout(grace_seconds):
                await process.stdin.wait_closed()
    if process.returncode is not None:
        await process.wait()
        return
    _signal_process(process, signal.SIGTERM)
    try:
        await asyncio.wait_for(process.wait(), timeout=grace_seconds)
        return
    except TimeoutError:
        pass
    _signal_process(process, getattr(signal, "SIGKILL", signal.SIGTERM))
    with contextlib.suppress(ProcessLookupError):
        await process.wait()


def _signal_process(process: asyncio.subprocess.Process, value: signal.Signals) -> None:
    if process.returncode is not None:
        return
    try:
        if os.name == "posix":
            os.killpg(process.pid, value)
        elif value == signal.SIGTERM:
            process.terminate()
        else:
            process.kill()
    except ProcessLookupError:
        return


class BridgeApplication:
    def __init__(
        self,
        *,
        route: str,
        authenticator: BearerAuthenticator,
        command: EngineCommand,
        budgets: BridgeBudgets,
        subprocess_environment: Mapping[str, str],
        human_style_ranks: Sequence[str] = (),
    ) -> None:
        if (
            not route.startswith("/")
            or route.startswith("//")
            or "?" in route
            or "#" in route
            or "\\" in route
            or any(ord(character) < 0x21 for character in route)
            or len(route.encode("utf-8")) > 128
        ):
            raise BridgeConfigurationError("WebSocket route must be an absolute path")
        self._route = route
        self._authenticator = authenticator
        self._command = command
        self._budgets = budgets
        self._subprocess_environment = dict(subprocess_environment)
        self._human_style_ranks = tuple(human_style_ranks)
        self._limiter = ConnectionLimiter(budgets.max_connections)

    async def process_request(self, connection: ServerConnection, request: Any) -> Any:
        if request.path != self._route:
            return connection.respond(HTTPStatus.NOT_FOUND, "Not found\n")
        try:
            authorization = request.headers.get_all("Authorization")
        except (KeyError, TypeError, AttributeError):
            authorization = []
        if not self._authenticator.accepts(authorization):
            return connection.respond(HTTPStatus.UNAUTHORIZED, "Unauthorized\n")
        return None

    async def handler(self, websocket: ServerConnection) -> None:
        if not await self._limiter.try_acquire():
            await websocket.close(code=1013, reason="Analysis service is busy")
            return
        try:
            await BridgeSession(
                websocket,
                self._command,
                self._budgets,
                subprocess_environment=self._subprocess_environment,
                human_style_ranks=self._human_style_ranks,
            ).run()
        finally:
            await self._limiter.release()


def build_tls_context(cert_file: Path, key_file: Path) -> ssl.SSLContext:
    certificate = _regular_file(cert_file, "TLS certificate")
    private_key = _regular_file(key_file, "TLS private key")
    if os.name == "posix":
        key_mode = stat.S_IMODE(private_key.stat().st_mode)
        if key_mode & 0o077:
            raise BridgeConfigurationError(
                "TLS private key must not be accessible by group or other users"
            )
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.minimum_version = ssl.TLSVersion.TLSv1_2
    context.options |= ssl.OP_NO_COMPRESSION
    try:
        context.load_cert_chain(certfile=certificate, keyfile=private_key)
    except (OSError, ssl.SSLError) as error:
        raise BridgeConfigurationError(
            "TLS certificate or private key is invalid"
        ) from error
    return context


def _regular_file(path: str | os.PathLike[str], label: str) -> Path:
    try:
        resolved = Path(path).expanduser().resolve(strict=True)
        metadata = resolved.stat()
    except (OSError, RuntimeError) as error:
        raise BridgeConfigurationError(f"{label} does not exist") from error
    if not stat.S_ISREG(metadata.st_mode):
        raise BridgeConfigurationError(f"{label} must be a regular file")
    return resolved


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="TLS-only WSS bridge for KataGo's Analysis JSONL engine"
    )
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8443)
    parser.add_argument("--route", default="/v1")
    parser.add_argument("--cert-file", required=True, type=Path)
    parser.add_argument("--key-file", required=True, type=Path)
    parser.add_argument("--engine", required=True, type=Path)
    parser.add_argument("--katago-config", required=True, type=Path)
    parser.add_argument("--model", required=True, type=Path)
    parser.add_argument("--human-model", type=Path)
    parser.add_argument("--service-manifest", required=True, type=Path)
    parser.add_argument("--audit-manifest", required=True, type=Path)
    parser.add_argument("--token-env", default=_AUTH_ENVIRONMENT_VARIABLE)
    parser.add_argument("--token-file", type=Path)
    parser.add_argument("--max-connections", type=int, default=1)
    parser.add_argument("--max-message-bytes", type=int, default=1024 * 1024)
    parser.add_argument("--max-frame-bytes", type=int, default=1024 * 1024)
    parser.add_argument("--max-lines-per-message", type=int, default=16)
    parser.add_argument("--max-line-bytes", type=int, default=1024 * 1024)
    parser.add_argument("--max-json-depth", type=int, default=32)
    parser.add_argument("--max-json-tokens", type=int, default=250_000)
    parser.add_argument("--max-requests", type=int, default=4096)
    parser.add_argument("--process-start-timeout", type=float, default=20.0)
    parser.add_argument("--process-timeout", type=float, default=50.0 * 60.0)
    parser.add_argument("--process-shutdown-timeout", type=float, default=5.0)
    return parser


async def _serve(arguments: argparse.Namespace) -> None:
    budgets = BridgeBudgets(
        max_connections=arguments.max_connections,
        max_message_bytes=arguments.max_message_bytes,
        max_frame_bytes=arguments.max_frame_bytes,
        max_lines_per_message=arguments.max_lines_per_message,
        max_line_bytes=arguments.max_line_bytes,
        max_json_depth=arguments.max_json_depth,
        max_json_structural_tokens=arguments.max_json_tokens,
        max_requests_per_connection=arguments.max_requests,
        process_start_timeout_seconds=arguments.process_start_timeout,
        process_timeout_seconds=arguments.process_timeout,
        process_shutdown_timeout_seconds=arguments.process_shutdown_timeout,
    )
    authenticator = load_bearer_authenticator(
        token_env=arguments.token_env, token_file=arguments.token_file
    )
    source_command = EngineCommand.validated(
        executable=arguments.engine,
        config=arguments.katago_config,
        model=arguments.model,
        human_model=arguments.human_model,
    )
    ssl_context = build_tls_context(arguments.cert_file, arguments.key_file)
    trust = load_runtime_trust(
        service_manifest=arguments.service_manifest,
        audit_manifest=arguments.audit_manifest,
        has_human_model=source_command.human_model is not None,
        route=arguments.route,
        port=arguments.port,
    )
    staged = stage_runtime_artifacts(
        trust,
        engine=source_command.executable,
        config=source_command.config,
        model=source_command.model,
        human_model=source_command.human_model,
    )
    try:
        command = EngineCommand.validated(
            executable=staged.engine,
            config=staged.config,
            model=staged.model,
            human_model=staged.human_model,
        )
        child_environment = _sanitized_child_environment(
            os.environ, excluded_environment_name=arguments.token_env
        )
        application = BridgeApplication(
            route=arguments.route,
            authenticator=authenticator,
            command=command,
            budgets=budgets,
            subprocess_environment=child_environment,
            human_style_ranks=trust.human_style_ranks,
        )
        quiet_transport_logger = logging.getLogger("katago_bridge.transport")
        quiet_transport_logger.addHandler(logging.NullHandler())
        quiet_transport_logger.propagate = False
        stop_requested = asyncio.Event()
        event_loop = asyncio.get_running_loop()
        installed_signals: list[signal.Signals] = []
        for shutdown_signal in (signal.SIGINT, signal.SIGTERM):
            try:
                event_loop.add_signal_handler(shutdown_signal, stop_requested.set)
                installed_signals.append(shutdown_signal)
            except (NotImplementedError, RuntimeError, ValueError):
                continue
        try:
            async with serve(
                application.handler,
                arguments.host,
                arguments.port,
                ssl=ssl_context,
                process_request=application.process_request,
                origins=[None],
                compression=None,
                server_header=None,
                open_timeout=10,
                ping_interval=20,
                ping_timeout=20,
                close_timeout=5,
                max_size=(budgets.max_message_bytes, budgets.max_frame_bytes),
                max_queue=4,
                write_limit=64 * 1024,
                logger=quiet_transport_logger,
            ):
                LOGGER.info(
                    "listening on %s:%d%s",
                    arguments.host,
                    arguments.port,
                    arguments.route,
                )
                await stop_requested.wait()
        finally:
            for shutdown_signal in installed_signals:
                event_loop.remove_signal_handler(shutdown_signal)
    finally:
        staged.cleanup()


def _sanitized_child_environment(
    source: Mapping[str, str], *, excluded_environment_name: str
) -> dict[str, str]:
    return {
        name: value
        for name, value in source.items()
        if name not in {excluded_environment_name, _AUTH_ENVIRONMENT_VARIABLE}
        and _SENSITIVE_CHILD_ENVIRONMENT.search(name) is None
    }


def _require_python_312() -> None:
    if sys.version_info[:2] != (3, 12):
        raise BridgeConfigurationError("KataGo bridge requires Python 3.12 exactly")


def main(argv: Sequence[str] | None = None) -> None:
    _require_python_312()
    parser = _build_parser()
    arguments = parser.parse_args(argv)
    if not 1 <= arguments.port <= 65535:
        parser.error("--port must be between 1 and 65535")
    logging.basicConfig(
        level=logging.INFO, format="%(levelname)s katago-bridge: %(message)s"
    )
    try:
        asyncio.run(_serve(arguments))
    except KeyboardInterrupt:
        return
    except BridgeConfigurationError as error:
        parser.error(str(error))


if __name__ == "__main__":
    main()
