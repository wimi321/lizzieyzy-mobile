"""Minimal, security-bounded WSS bridge for KataGo's JSONL analysis engine."""

from .bridge import BridgeBudgets, BridgeSession, EngineCommand

__all__ = ["BridgeBudgets", "BridgeSession", "EngineCommand"]
__version__ = "0.1.0"
