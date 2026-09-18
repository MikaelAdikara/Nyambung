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

-- Login email + kata sandi terapis. `therapist` = nama tampilan yang sama dengan therapist_account,
-- jadi akun login dan token env menunjuk identitas terapis yang sama.
CREATE TABLE IF NOT EXISTS therapist_login (
  email         TEXT PRIMARY KEY,
  therapist     TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  created_at    TEXT NOT NULL
);

-- Sesi dari login. Hanya SHA-256 token yang disimpan; baris dihapus saat keluar.
CREATE TABLE IF NOT EXISTS therapist_session (
  token_hash TEXT PRIMARY KEY,
  therapist  TEXT NOT NULL,
  created_at TEXT NOT NULL,
  expires_at TEXT NOT NULL
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

-- Catatan sesi tatap muka (D4). Milik terapis: keluarga tidak pernah melihat `note`. Keluarga hanya menerima
-- `family_text` setelah terapis menekan "Kirim ringkasan ke keluarga" (`shared_at` terisi).
CREATE TABLE IF NOT EXISTS session_note (
  note_id      TEXT PRIMARY KEY,
  child_id     TEXT NOT NULL REFERENCES child(child_id),
  therapist    TEXT NOT NULL,
  session_date TEXT NOT NULL,
  note         TEXT NOT NULL,
  focus        TEXT,
  next_session TEXT,
  created_at   TEXT NOT NULL,
  updated_at   TEXT NOT NULL,
  family_text  TEXT,
  shared_at    TEXT
);
CREATE INDEX IF NOT EXISTS idx_session_child ON session_note(child_id, session_date);

-- Lama satu tinjauan dasbor atas satu anak (D2–D4 terbuka dan terlihat), untuk kartu D1 "Waktu tinjauan".
CREATE TABLE IF NOT EXISTS review_log (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  therapist   TEXT NOT NULL,
  child_id    TEXT NOT NULL,
  seconds     INTEGER NOT NULL,
  recorded_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_review_therapist ON review_log(therapist, recorded_at);

-- Klon suara keluarga (ElevenLabs). Hanya `voice_id` yang disimpan; rekaman sampel tidak pernah ditulis ke disk.
-- Dicabut orang tua → voice_id dihapus di ElevenLabs dan di sini (revoked_at terisi).
CREATE TABLE IF NOT EXISTS voice_clone (
  child_id   TEXT PRIMARY KEY REFERENCES child(child_id),
  voice_id   TEXT,
  consent_by TEXT NOT NULL,
  consent_at TEXT NOT NULL,
  revoked_at TEXT
);

-- Frasa: teks bebas + klip suara yang dibuat sekali di server, lalu diunduh dan diputar luring di perangkat.
-- `created_by` = 'keluarga' atau nama terapis. Frasa dari terapis berstatus usulan; statusnya diturunkan dari
-- peristiwa TGT dengan context = phrase_id, sama seperti target kosakata.
CREATE TABLE IF NOT EXISTS phrase (
  phrase_id  TEXT PRIMARY KEY,
  child_id   TEXT NOT NULL REFERENCES child(child_id),
  text       TEXT NOT NULL,
  voice      TEXT NOT NULL,
  created_by TEXT NOT NULL,
  created_at TEXT NOT NULL,
  audio_file TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_phrase_child ON phrase(child_id, created_at);
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
