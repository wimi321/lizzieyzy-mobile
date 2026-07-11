from __future__ import annotations

import json
import logging
import os
import shutil
import ssl
import subprocess
import tempfile
import unittest
from pathlib import Path

from websockets.asyncio.client import connect
from websockets.asyncio.server import serve
from websockets.exceptions import InvalidStatus

from katago_bridge.bridge import (
    BearerAuthenticator,
    BridgeApplication,
    BridgeBudgets,
    EngineCommand,
    build_tls_context,
)


class WssIntegrationTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self) -> None:
        openssl = shutil.which("openssl")
        if openssl is None:
            self.skipTest("openssl is required for the ephemeral TLS fixture")
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.certificate = self.root / "certificate.pem"
        self.private_key = self.root / "private-key.pem"
        subprocess.run(
            [
                openssl,
                "req",
                "-x509",
                "-newkey",
                "rsa:2048",
                "-nodes",
                "-keyout",
                str(self.private_key),
                "-out",
                str(self.certificate),
                "-days",
                "1",
                "-subj",
                "/CN=127.0.0.1",
                "-addext",
                "subjectAltName=IP:127.0.0.1",
            ],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        self.private_key.chmod(0o600)
        self.engine = self.root / "katago"
        shutil.copyfile(Path(__file__).with_name("fake_katago.py"), self.engine)
        self.engine.chmod(0o700)
        self.config = self.root / "analysis.cfg"
        self.model = self.root / "normal-model.bin.gz"
        self.human_model = self.root / "human-model.bin.gz"
        self.config.write_text(
            "reportAnalysisWinratesAs = SIDETOMOVE\n"
            "logAllRequests = false\n"
            "logAllResponses = false\n"
            "logErrorsAndWarnings = false\n"
            "logSearchInfo = false\n"
        )
        self.model.write_bytes(b"normal")
        self.human_model.write_bytes(b"human")
        self.audit = self.root / "audit.jsonl"

    def tearDown(self) -> None:
        self.temporary.cleanup()

    async def test_real_tls_handshake_auth_and_jsonl_relay(self) -> None:
        credential = "W" * 48
        environment = dict(os.environ)
        environment["FAKE_KATAGO_AUDIT_PATH"] = str(self.audit)
        application = BridgeApplication(
            route="/v1",
            authenticator=BearerAuthenticator.from_token(credential),
            command=EngineCommand.validated(
                executable=self.engine,
                config=self.config,
                model=self.model,
                human_model=self.human_model,
            ),
            budgets=BridgeBudgets(process_timeout_seconds=5),
            subprocess_environment=environment,
        )
        transport_logger = logging.getLogger("katago_bridge.integration.transport")
        transport_logger.addHandler(logging.NullHandler())
        transport_logger.propagate = False
        process_id: int | None = None
        async with serve(
            application.handler,
            "127.0.0.1",
            0,
            ssl=build_tls_context(self.certificate, self.private_key),
            process_request=application.process_request,
            origins=[None],
            compression=None,
            server_header=None,
            max_size=(1024 * 1024, 1024 * 1024),
            logger=transport_logger,
        ) as server:
            port = server.sockets[0].getsockname()[1]
            endpoint = f"wss://127.0.0.1:{port}/v1"
            client_tls = ssl.create_default_context(cafile=str(self.certificate))
            with self.assertRaises(InvalidStatus) as unauthenticated:
                async with connect(endpoint, ssl=client_tls):
                    pass
            self.assertEqual(unauthenticated.exception.response.status_code, 401)
            self.assertFalse(self.audit.exists())

            async with connect(
                endpoint,
                ssl=client_tls,
                additional_headers={"Authorization": f"Bearer {credential}"},
            ) as websocket:
                query = json.dumps(_app_query("integration"))
                await websocket.send(query)
                response = json.loads(await websocket.recv())
                self.assertEqual(response["raw"], query)
                self.assertEqual(
                    response["humanModel"], str(self.human_model.resolve())
                )
                process_id = json.loads(self.audit.read_text().splitlines()[0])["pid"]
        self.assertIsNotNone(process_id)
        self.assertFalse(_process_exists(process_id))


def _process_exists(process_id: int) -> bool:
    try:
        os.kill(process_id, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def _app_query(request_id: str) -> dict[str, object]:
    return {
        "id": request_id,
        "initialStones": [],
        "initialPlayer": "B",
        "moves": [],
        "rules": "chinese",
        "komi": 7.5,
        "boardXSize": 19,
        "boardYSize": 19,
        "analyzeTurns": [0],
        "maxVisits": 1000,
        "analysisPVLen": 20,
        "includeOwnership": True,
        "includePolicy": True,
    }


if __name__ == "__main__":
    unittest.main()
