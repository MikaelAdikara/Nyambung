"""SQLite server: satu koneksi, WAL, foreign keys, skema kontrak §2.

Tabel `event` append-only: trigger menolak UPDATE dan DELETE. Semua waktu server ISO-8601 UTC berakhiran `Z`.
"""

from __future__ import annotations

import os
import sqlite3
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterator

DEFAULT_DB_PATH = Path(__file__).resolve().parent.parent / "data" / "nyambung.db"

SCHEMA = """
CREATE TABLE IF NOT EXISTS child (
  child_id      TEXT PRIMARY KEY,
  nickname      TEXT NOT NULL,
  age_years     INTEGER,
  routine       TEXT,
  first_seen_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS event (
  event_id     TEXT PRIMARY KEY,
  child_id     TEXT NOT NULL REFERENCES child(child_id),
  ts_device    TEXT NOT NULL,
  ts_utc       TEXT NOT NULL,
  hour_local   INTEGER NOT NULL,
  date_local   TEXT NOT NULL,
  content      TEXT NOT NULL,
  method       TEXT NOT NULL,
  actor        TEXT NOT NULL,
  prompt_level TEXT NOT NULL,
  context      TEXT,
  session_id   TEXT NOT NULL,
  received_at  TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_event_child_ts ON event(child_id, ts_utc);

CREATE TRIGGER IF NOT EXISTS event_no_update BEFORE UPDATE ON event
BEGIN SELECT RAISE(ABORT, 'event append-only'); END;
CREATE TRIGGER IF NOT EXISTS event_no_delete BEFORE DELETE ON event
BEGIN SELECT RAISE(ABORT, 'event append-only'); END;

CREATE TABLE IF NOT EXISTS sync_log (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  child_id    TEXT NOT NULL,
  received_at TEXT NOT NULL,
  accepted    INTEGER NOT NULL,
  duplicates  INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_sync_child ON sync_log(child_id, received_at);

CREATE TABLE IF NOT EXISTS therapist_account (
  token_hash TEXT PRIMARY KEY,
  therapist  TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS invite (
  invite_code TEXT PRIMARY KEY,
  therapist   TEXT NOT NULL,
  created_at  TEXT NOT NULL,
  used_at     TEXT
);

CREATE TABLE IF NOT EXISTS therapist_link (
  link_id           TEXT PRIMARY KEY,
  invite_code       TEXT NOT NULL,
  child_id          TEXT NOT NULL REFERENCES child(child_id),
  therapist         TEXT NOT NULL,
  linked_at         TEXT NOT NULL,
  revoked_at        TEXT,
  device_token_hash TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS vocab_target (
  target_id  TEXT PRIMARY KEY,
  child_id   TEXT NOT NULL REFERENCES child(child_id),
  words      TEXT NOT NULL,
  note       TEXT,
  week_index INTEGER,
  routine    TEXT,
  therapist  TEXT NOT NULL,
  created_at TEXT NOT NULL
);
"""


def utc_iso(dt: datetime) -> str:
    """UTC ISO-8601 berakhiran `Z`, presisi detik."""
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


def parse_utc(s: str) -> datetime:
    return datetime.fromisoformat(s.replace("Z", "+00:00"))


def db_path() -> Path:
    return Path(os.environ.get("NYAMBUNG_DB_PATH", str(DEFAULT_DB_PATH)))


def connect(path: Path | str | None = None) -> sqlite3.Connection:
    p = Path(path) if path is not None else db_path()
    p.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(p), check_same_thread=False, isolation_level=None)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    conn.executescript(SCHEMA)
    return conn


@contextmanager
def transaction(conn: sqlite3.Connection) -> Iterator[sqlite3.Connection]:
    """BEGIN … COMMIT, ROLLBACK bila gagal."""
    conn.execute("BEGIN IMMEDIATE")
    try:
        yield conn
    except BaseException:
        conn.execute("ROLLBACK")
        raise
    conn.execute("COMMIT")
