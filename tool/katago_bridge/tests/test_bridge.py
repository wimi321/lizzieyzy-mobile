from __future__ import annotations

import asyncio
import hmac
import json
import os
import shutil
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from katago_bridge.bridge import (
    BearerAuthenticator,
    BridgeApplication,
    BridgeBudgetExceeded,
    BridgeBudgets,
    BridgeConfigurationError,
    BridgeProtocolError,
    BridgeSession,
    ConnectionLimiter,
    EngineCommand,
    _sanitized_child_environment,
    _validate_request,
    build_tls_context,
    load_bearer_authenticator,
)
from katago_bridge.trust import parse_katago_config


class _FakeWebSocket:
    _END = object()

    def __init__(self) -> None:
        self._incoming: asyncio.Queue[str | bytes | object] = asyncio.Queue()
        self._outgoing: asyncio.Queue[str] = asyncio.Queue()
        self.close_calls: list[tuple[int, str]] = []

    def __aiter__(self) -> _FakeWebSocket:
        return self

    async def __anext__(self) -> str | bytes:
        value = await self._incoming.get()
        if value is self._END:
            raise StopAsyncIteration
        return value  # type: ignore[return-value]

    async def feed(self, value: str | bytes) -> None:
        await self._incoming.put(value)

    async def finish(self) -> None:
        await self._incoming.put(self._END)

    async def send(self, message: str) -> None:
        await self._outgoing.put(message)

    async def next_sent(self) -> str:
        return await asyncio.wait_for(self._outgoing.get(), timeout=5)

    async def close(self, code: int = 1000, reason: str = "") -> None:
        self.close_calls.append((code, reason))


class AuthenticationTests(unittest.TestCase):
    TOKEN = "A" * 48

    def test_constant_time_digest_comparison(self) -> None:
        authenticator = BearerAuthenticator.from_token(self.TOKEN)
        original = hmac.compare_digest
        with mock.patch(
            "katago_bridge.bridge.hmac.compare_digest", wraps=original
        ) as comparison:
            self.assertTrue(authenticator.accepts([f"Bearer {self.TOKEN}"]))
            self.assertFalse(authenticator.accepts(["Bearer " + "B" * 48]))
            self.assertFalse(
                authenticator.accepts([f"Bearer {self.TOKEN}", f"Bearer {self.TOKEN}"])
            )
        self.assertEqual(comparison.call_count, 3)
        for call in comparison.call_args_list:
            self.assertEqual(len(call.args[0]), 32)
            self.assertEqual(len(call.args[1]), 32)

    def test_token_source_is_environment_or_an_owned_0600_file(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            token_file = Path(directory, "token")
            token_file.write_text(self.TOKEN + "\n", encoding="ascii")
            token_file.chmod(0o600)
            with mock.patch.dict(os.environ, {}, clear=True):
                from_file = load_bearer_authenticator(token_file=token_file)
                self.assertTrue(from_file.accepts([f"Bearer {self.TOKEN}"]))
            token_file.chmod(0o644)
            with mock.patch.dict(os.environ, {}, clear=True):
                with self.assertRaisesRegex(BridgeConfigurationError, "0600"):
                    load_bearer_authenticator(token_file=token_file)
            token_file.chmod(0o600)
            with mock.patch.dict(
                os.environ, {"LIZZIEYZY_BRIDGE_TOKEN": self.TOKEN}, clear=True
            ):
                with self.assertRaisesRegex(BridgeConfigurationError, "both"):
                    load_bearer_authenticator(token_file=token_file)


class ConnectionLimiterTests(unittest.IsolatedAsyncioTestCase):
    def test_cli_tunable_budgets_keep_absolute_safety_ceilings(self) -> None:
        with self.assertRaisesRegex(BridgeConfigurationError, "hard safety ceiling"):
            BridgeBudgets(max_message_bytes=8 * 1024 * 1024 + 1)

    async def test_rejects_connections_over_the_process_cap(self) -> None:
        limiter = ConnectionLimiter(1)
        self.assertTrue(await limiter.try_acquire())
        self.assertFalse(await limiter.try_acquire())
        await limiter.release()
        self.assertTrue(await limiter.try_acquire())
        await limiter.release()


class _Headers:
    def __init__(self, values: list[str]) -> None:
        self._values = values

    def get_all(self, name: str) -> list[str]:
        return self._values if name == "Authorization" else []


class _HandshakeConnection:
    def respond(self, status: object, text: str) -> tuple[object, str]:
        return status, text


class HandshakeSecurityTests(unittest.IsolatedAsyncioTestCase):
    async def test_route_and_bearer_authentication_run_before_handler(self) -> None:
        token = "C" * 48
        application = BridgeApplication(
            route="/v1",
            authenticator=BearerAuthenticator.from_token(token),
            command=EngineCommand(Path("engine"), Path("config"), Path("model")),
            budgets=BridgeBudgets(),
            subprocess_environment={},
        )
        connection = _HandshakeConnection()
        wrong_path = type("Request", (), {"path": "/other", "headers": _Headers([])})()
        missing_token = type("Request", (), {"path": "/v1", "headers": _Headers([])})()
        valid = type(
            "Request",
            (),
            {"path": "/v1", "headers": _Headers([f"Bearer {token}"])},
        )()
        self.assertEqual(
            (await application.process_request(connection, wrong_path))[0].value,
            404,
        )
        self.assertEqual(
            (await application.process_request(connection, missing_token))[0].value,
            401,
        )
        self.assertIsNone(await application.process_request(connection, valid))

    async def test_tls_files_are_mandatory_and_child_environment_is_scrubbed(
        self,
    ) -> None:
        with self.assertRaises(BridgeConfigurationError):
            build_tls_context(Path("missing-cert"), Path("missing-key"))
        child = _sanitized_child_environment(
            {
                "PATH": "/bin",
                "CUDA_VISIBLE_DEVICES": "0",
                "LIZZIEYZY_BRIDGE_TOKEN": "do-not-copy",
                "SOME_API_KEY": "do-not-copy",
            },
            excluded_environment_name="LIZZIEYZY_BRIDGE_TOKEN",
        )
        self.assertEqual(child, {"PATH": "/bin", "CUDA_VISIBLE_DEVICES": "0"})


class RequestSchemaTests(unittest.TestCase):
    def test_accepts_only_the_bounded_app_analysis_schema(self) -> None:
        for board_size in (9, 13, 19):
            query = _app_query(f"valid-{board_size}")
            query["boardXSize"] = board_size
            query["boardYSize"] = board_size
            validated = _validate_request(
                query,
                allowed_human_profiles=frozenset(),
            )
            self.assertEqual(validated.analyze_turns, (0,))
        cases = [
            ({"unknown": True}, BridgeProtocolError),
            ({"maxVisits": 20_001}, BridgeBudgetExceeded),
            ({"maxVisits": True}, BridgeProtocolError),
            ({"analysisPVLen": 129}, BridgeBudgetExceeded),
            ({"boardXSize": 10, "boardYSize": 10}, BridgeProtocolError),
            ({"initialStones": "none"}, BridgeProtocolError),
            ({"rules": "unsupported"}, BridgeProtocolError),
            ({"komi": float("inf")}, BridgeProtocolError),
            ({"includeOwnership": 1}, BridgeProtocolError),
            ({"includePolicy": False}, BridgeProtocolError),
            ({"analyzeTurns": [True]}, BridgeProtocolError),
        ]
        for changes, error in cases:
            with self.subTest(changes=changes):
                query = _app_query("invalid")
                query.update(changes)
                with self.assertRaises(error):
                    _validate_request(
                        query,
                        allowed_human_profiles=frozenset(),
                    )

    def test_limits_moves_stones_and_human_overrides(self) -> None:
        too_many_moves = _app_query("moves")
        too_many_moves["moves"] = [
            ["B" if index % 2 == 0 else "W", "pass"] for index in range(1000)
        ]
        too_many_moves["analyzeTurns"] = list(range(1001))
        with self.assertRaises(BridgeBudgetExceeded):
            _validate_request(
                too_many_moves,
                allowed_human_profiles=frozenset(),
            )
        too_many_stones = _app_query("stones")
        too_many_stones["boardXSize"] = 9
        too_many_stones["boardYSize"] = 9
        too_many_stones["initialStones"] = [["B", "A1"]] * 82
        with self.assertRaises(BridgeBudgetExceeded):
            _validate_request(
                too_many_stones,
                allowed_human_profiles=frozenset(),
            )
        human = _app_query("human")
        human["overrideSettings"] = {
            "humanSLProfile": "rank_3k",
            "ignorePreRootHistory": False,
        }
        _validate_request(
            human,
            allowed_human_profiles=frozenset({"rank_3k"}),
        )
        with self.assertRaises(BridgeProtocolError):
            _validate_request(
                human,
                allowed_human_profiles=frozenset({"rank_1d"}),
            )


class BridgeSessionTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        fake_source = Path(__file__).with_name("fake_katago.py")
        self.fake_engine = self.root / "katago"
        shutil.copyfile(fake_source, self.fake_engine)
        self.fake_engine.chmod(0o700)
        self.config = self.root / "analysis.cfg"
        self.model = self.root / "normal.bin.gz"
        self.human_model = self.root / "human.bin.gz"
        self.config.write_text(_PRIVATE_ANALYSIS_CONFIG)
        self.model.write_bytes(b"normal model")
        self.human_model.write_bytes(b"human model")
        self.audit = self.root / "audit.jsonl"
        self.command = EngineCommand.validated(
            executable=self.fake_engine,
            config=self.config,
            model=self.model,
            human_model=self.human_model,
        )
        self.environment = dict(os.environ)
        self.environment["FAKE_KATAGO_AUDIT_PATH"] = str(self.audit)
        self.environment.pop("LIZZIEYZY_BRIDGE_TOKEN", None)

    async def test_katago_request_logging_must_be_disabled(self) -> None:
        unsafe_config = self.root / "unsafe-analysis.cfg"
        unsafe_config.write_text(
            _PRIVATE_ANALYSIS_CONFIG.replace(
                "logAllRequests = false", "logAllRequests = true"
            )
        )
        with self.assertRaisesRegex(BridgeConfigurationError, "explicitly set"):
            parse_katago_config(unsafe_config)

    async def asyncTearDown(self) -> None:
        self.temporary.cleanup()

    def _session(
        self, websocket: _FakeWebSocket, **changes: int | float
    ) -> BridgeSession:
        defaults: dict[str, int | float] = {
            "process_start_timeout_seconds": 3.0,
            "process_timeout_seconds": 10.0,
            "process_shutdown_timeout_seconds": 1.0,
        }
        defaults.update(changes)
        return BridgeSession(
            websocket,
            self.command,
            BridgeBudgets(**defaults),
            subprocess_environment=self.environment,
        )

    async def test_plain_and_terminate_requests_are_forwarded(self) -> None:
        websocket = _FakeWebSocket()
        session = self._session(websocket)
        running = asyncio.create_task(session.run())
        query = json.dumps(
            _app_query("review-1", moves=[["B", "Q16"]]),
            separators=(", ", ": "),
        )
        await websocket.feed(query)
        response = json.loads(await websocket.next_sent())
        self.assertEqual(response["raw"], query)
        self.assertEqual(response["model"], str(self.model.resolve()))
        self.assertEqual(response["humanModel"], str(self.human_model.resolve()))
        self.assertFalse(response["bridgeTokenVisible"])

        terminate = (
            '{"id":"__lizzieyzy_terminate_0","action":"terminate",'
            '"terminateId":"review-1"}'
        )
        await websocket.feed(terminate)
        acknowledgement = json.loads(await websocket.next_sent())
        self.assertEqual(acknowledgement["action"], "terminate")
        self.assertEqual(acknowledgement["terminateId"], "review-1")
        await websocket.finish()
        await asyncio.wait_for(running, timeout=3)

        events = self._audit_events()
        self.assertEqual(
            events[0]["argv"],
            [
                "analysis",
                "-config",
                str(self.config.resolve()),
                "-model",
                str(self.model.resolve()),
                "-human-model",
                str(self.human_model.resolve()),
            ],
        )
        self.assertEqual([event["raw"] for event in events[1:]], [query, terminate])
        self.assertIsNotNone(session.process)
        self.assertIsNotNone(session.process.returncode)

    async def test_terminate_is_relayed_and_disconnect_reaps_the_process(self) -> None:
        websocket = _FakeWebSocket()
        session = self._session(websocket)
        running = asyncio.create_task(session.run())
        await websocket.feed(json.dumps(_app_query("slow")))
        await websocket.feed(
            '{"id":"cancel","action":"terminate","terminateId":"slow"}'
        )
        acknowledgement = json.loads(await websocket.next_sent())
        self.assertEqual(acknowledgement["terminateId"], "slow")
        self.assertIsNotNone(session.process)
        process_id = session.process.pid
        await websocket.finish()
        await asyncio.wait_for(running, timeout=3)
        self.assertFalse(_process_exists(process_id))

    async def test_line_request_and_json_depth_budgets_fail_closed(self) -> None:
        cases = [
            (
                {"max_line_bytes": 24},
                '{"id":"request-too-long"}',
            ),
            (
                {"max_requests_per_connection": 1},
                f"{json.dumps(_app_query('one'))}\n{json.dumps(_app_query('two'))}",
            ),
            (
                {"max_json_depth": 2},
                '{"id":"deep","value":{"nested":[]}}',
            ),
        ]
        for changes, payload in cases:
            with self.subTest(changes=changes):
                websocket = _FakeWebSocket()
                session = self._session(websocket, **changes)
                running = asyncio.create_task(session.run())
                await websocket.feed(payload)
                await asyncio.wait_for(running, timeout=3)
                self.assertEqual(websocket.close_calls[0][0], 1009)
                self.assertIsNotNone(session.process)
                self.assertIsNotNone(session.process.returncode)

    async def test_terminate_must_target_this_connections_analysis(self) -> None:
        websocket = _FakeWebSocket()
        session = self._session(websocket)
        running = asyncio.create_task(session.run())
        await websocket.feed(
            '{"id":"cancel","action":"terminate","terminateId":"foreign"}'
        )
        await asyncio.wait_for(running, timeout=3)
        self.assertEqual(websocket.close_calls[0][0], 1008)

    async def test_completed_results_release_the_concurrency_budget(self) -> None:
        websocket = _FakeWebSocket()
        session = self._session(websocket)
        running = asyncio.create_task(session.run())
        for index in range(6):
            await websocket.feed(json.dumps(_app_query(f"sequential-{index}")))
            response = json.loads(await websocket.next_sent())
            self.assertEqual(response["turnNumber"], 0)
        await websocket.finish()
        await asyncio.wait_for(running, timeout=3)
        self.assertEqual(websocket.close_calls, [])

    async def test_process_lifetime_budget_closes_and_reaps_engine(self) -> None:
        websocket = _FakeWebSocket()
        session = self._session(websocket, process_timeout_seconds=0.1)
        await asyncio.wait_for(session.run(), timeout=3)
        self.assertEqual(websocket.close_calls[0][0], 1011)
        self.assertIsNotNone(session.process)
        process_id = session.process.pid
        self.assertIsNotNone(session.process.returncode)
        self.assertFalse(_process_exists(process_id))

    def _audit_events(self) -> list[dict[str, object]]:
        if not self.audit.exists():
            return []
        return [json.loads(line) for line in self.audit.read_text().splitlines()]


def _process_exists(process_id: int) -> bool:
    try:
        os.kill(process_id, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


_PRIVATE_ANALYSIS_CONFIG = """\
reportAnalysisWinratesAs = SIDETOMOVE
logAllRequests = false
logAllResponses = false
logErrorsAndWarnings = false
logSearchInfo = false
"""


def _app_query(
    request_id: str, *, moves: list[list[str]] | None = None
) -> dict[str, object]:
    submitted_moves = moves or []
    return {
        "id": request_id,
        "initialStones": [],
        "initialPlayer": "B",
        "moves": submitted_moves,
        "rules": "chinese",
        "komi": 7.5,
        "boardXSize": 19,
        "boardYSize": 19,
        "analyzeTurns": list(range(len(submitted_moves) + 1)),
        "maxVisits": 1000,
        "analysisPVLen": 20,
        "includeOwnership": True,
        "includePolicy": True,
    }


if __name__ == "__main__":
    unittest.main()
