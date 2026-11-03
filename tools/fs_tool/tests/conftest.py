"""Pytest configuration for fs-tool tests."""

from __future__ import annotations

import sys
from pathlib import Path

# Ensure fs_tool is importable
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))


def pytest_configure(config):
    config.addinivalue_line("markers", "slow: marks tests as slow")
    config.addinivalue_line("markers", "integration: marks tests as integration tests")