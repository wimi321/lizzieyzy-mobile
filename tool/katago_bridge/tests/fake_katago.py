#!/usr/bin/env python3
"""Subprocess test double for KataGo's Analysis JSONL command."""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any


def _arguments() -> argparse.Namespace:
    if len(sys.argv) < 2 or sys.argv[1] != "analysis":
        raise SystemExit(64)
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("-config", required=True)
    parser.add_argument("-model", required=True)
    parser.add_argument("-human-model")
    return parser.parse_args(sys.argv[2:])


def _audit(value: dict[str, Any]) -> None:
    path = os.environ.get("FAKE_KATAGO_AUDIT_PATH")
    if path is None:
        return
    with Path(path).open("a", encoding="utf-8") as stream:
        stream.write(json.dumps(value, sort_keys=True, separators=(",", ":")))
        stream.write("\n")


def main() -> None:
    arguments = _arguments()
    startup = {
        "event": "start",
        "pid": os.getpid(),
        "argv": sys.argv[1:],
        "bridgeTokenVisible": "LIZZIEYZY_BRIDGE_TOKEN" in os.environ,
    }
    _audit(startup)
    for raw_line in sys.stdin:
        line = raw_line.rstrip("\r\n")
        request = json.loads(line)
        _audit({"event": "request", "raw": line})
        if request.get("action") == "terminate":
            response = {
                "id": request["id"],
                "action": "terminate",
                "terminateId": request["terminateId"],
            }
        elif request.get("id") == "slow":
            continue
        else:
            response = {
                "id": request["id"],
                "turnNumber": request["analyzeTurns"][0],
                "raw": line,
                "config": arguments.config,
                "model": arguments.model,
                "humanModel": arguments.human_model,
                "bridgeTokenVisible": startup["bridgeTokenVisible"],
            }
        print(json.dumps(response, sort_keys=True, separators=(",", ":")), flush=True)


if __name__ == "__main__":
    main()
