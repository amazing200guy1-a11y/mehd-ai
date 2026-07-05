"""
Mehd AI — Storage Tests
=========================
Proves the storage abstraction works correctly.
Run with: python -m pytest tests/test_storage.py -v
"""

import pytest
import asyncio
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from storage import MemoryStorage


# ──────────────────────────────────────────────
#  FIXTURES
# ──────────────────────────────────────────────

@pytest.fixture
def store():
    return MemoryStorage()


# ──────────────────────────────────────────────
#  TEST 1: Basic CRUD
# ──────────────────────────────────────────────

class TestBasicCRUD:
    """Set, get, delete must work correctly."""

    def test_set_and_get(self, store):
        asyncio.run(
            store.set("drawings", "user1_EURUSD", {"lines": [1, 2, 3]})
        )
        result = asyncio.run(
            store.get("drawings", "user1_EURUSD")
        )
        assert result == {"lines": [1, 2, 3]}

    def test_get_nonexistent_returns_none(self, store):
        result = asyncio.run(
            store.get("drawings", "does_not_exist")
        )
        assert result is None

    def test_delete_existing(self, store):
        asyncio.run(
            store.set("briefs", "T_123", {"symbol": "EURUSD"})
        )
        deleted = asyncio.run(
            store.delete("briefs", "T_123")
        )
        assert deleted is True
        result = asyncio.run(
            store.get("briefs", "T_123")
        )
        assert result is None

    def test_delete_nonexistent_returns_false(self, store):
        deleted = asyncio.run(
            store.delete("briefs", "nope")
        )
        assert deleted is False

    def test_overwrite(self, store):
        asyncio.run(
            store.set("data", "key1", {"v": 1})
        )
        asyncio.run(
            store.set("data", "key1", {"v": 2})
        )
        result = asyncio.run(
            store.get("data", "key1")
        )
        assert result == {"v": 2}


# ──────────────────────────────────────────────
#  TEST 2: Collections
# ──────────────────────────────────────────────

class TestCollections:
    """Collections must be isolated from each other."""

    def test_different_collections_isolated(self, store):
        asyncio.run(
            store.set("drawings", "key1", {"type": "drawing"})
        )
        asyncio.run(
            store.set("briefs", "key1", {"type": "brief"})
        )
        d = asyncio.run(
            store.get("drawings", "key1")
        )
        b = asyncio.run(
            store.get("briefs", "key1")
        )
        assert d["type"] == "drawing"
        assert b["type"] == "brief"

    def test_list_keys(self, store):
        asyncio.run(
            store.set("trades", "t1", {"a": 1})
        )
        asyncio.run(
            store.set("trades", "t2", {"a": 2})
        )
        keys = asyncio.run(
            store.list_keys("trades")
        )
        assert sorted(keys) == ["t1", "t2"]

    def test_get_all(self, store):
        asyncio.run(
            store.set("data", "a", {"v": 1})
        )
        asyncio.run(
            store.set("data", "b", {"v": 2})
        )
        all_data = asyncio.run(
            store.get_all("data")
        )
        assert len(all_data) == 2
        assert all_data["a"] == {"v": 1}

    def test_count(self, store):
        asyncio.run(
            store.set("items", "x", {})
        )
        asyncio.run(
            store.set("items", "y", {})
        )
        c = asyncio.run(
            store.count("items")
        )
        assert c == 2


# ──────────────────────────────────────────────
#  TEST 3: Increment
# ──────────────────────────────────────────────

class TestIncrement:
    """Atomic increment for counters (analysis counts, etc.)."""

    def test_increment_new_key(self, store):
        result = asyncio.run(
            store.increment("counters", "user1", "analyses")
        )
        assert result == 1

    def test_increment_existing(self, store):
        asyncio.run(
            store.increment("counters", "user1", "analyses")
        )
        result = asyncio.run(
            store.increment("counters", "user1", "analyses")
        )
        assert result == 2

    def test_increment_by_amount(self, store):
        result = asyncio.run(
            store.increment("counters", "budget", "spent_usd", amount=5)
        )
        assert result == 5

    def test_empty_collection_count(self, store):
        c = asyncio.run(
            store.count("empty_collection")
        )
        assert c == 0
