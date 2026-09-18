"""Autentikasi Bearer (kontrak §4). Server hanya menyimpan SHA-256 token.

- Terapis: token dari env `NYAMBUNG_THERAPIST_TOKENS="tokA:Bu Rina (ilustratif);tokB:Pak Dimas"`, ≥ 16 karakter.
- Perangkat: token dikeluarkan sekali saat `redeem`, berlaku untuk `child_id` tautannya saja.
"""

from __future__ import annotations

import hashlib
import logging
import secrets
import sqlite3
from dataclasses import dataclass
from typing import Optional

from fastapi import HTTPException, Request

from .db import now_utc, utc_iso

log = logging.getLogger("nyambung.auth")

MIN_TOKEN_LEN = 16
# Tanpa I, O, 0, 1 supaya tidak tertukar saat dibaca.
INVITE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
INVITE_LEN = 8
INVITE_TTL_DAYS = 7


def sha256(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def new_device_token() -> str:
    return secrets.token_urlsafe(32)


def new_invite_code() -> str:
    return "".join(secrets.choice(INVITE_ALPHABET) for _ in range(INVITE_LEN))


def parse_therapist_env(raw: str | None) -> list[tuple[str, str]]:
    """`"tok:Nama;tok2:Nama 2"` → [(tok, Nama), ...]. Token < 16 karakter dilewati dengan peringatan."""
    out: list[tuple[str, str]] = []
    for part in (raw or "").split(";"):
        part = part.strip()
        if not part or ":" not in part:
            continue
        token, name = part.split(":", 1)
        token, name = token.strip(), name.strip()
        if len(token) < MIN_TOKEN_LEN:
            log.warning("token terapis untuk %r dilewati: kurang dari %d karakter", name, MIN_TOKEN_LEN)
            continue
        if name:
            out.append((token, name))
    return out


def seed_therapists(conn: sqlite3.Connection, raw: str | None) -> int:
    pairs = parse_therapist_env(raw)
    now = utc_iso(now_utc())
    for token, name in pairs:
        conn.execute("DELETE FROM therapist_account WHERE therapist = ? AND token_hash != ?", (name, sha256(token)))
        conn.execute(
            "INSERT OR IGNORE INTO therapist_account (token_hash, therapist, created_at) VALUES (?, ?, ?)",
            (sha256(token), name, now),
        )
    return len(pairs)


@dataclass(frozen=True)
class Principal:
    kind: str  # "therapist" | "device"
    therapist: Optional[str] = None
    link_id: Optional[str] = None
    child_id: Optional[str] = None


def _bearer(request: Request) -> str:
    header = request.headers.get("authorization", "")
    scheme, _, token = header.partition(" ")
    if scheme.lower() != "bearer" or not token.strip():
        raise HTTPException(status_code=401, detail="token diperlukan")
    return token.strip()


def resolve(conn: sqlite3.Connection, request: Request) -> Principal:
    """Token → terapis atau perangkat. Tidak dikenal atau tautan dicabut → 401."""
    h = sha256(_bearer(request))
    row = conn.execute("SELECT therapist FROM therapist_account WHERE token_hash = ?", (h,)).fetchone()
    if row:
        return Principal(kind="therapist", therapist=row["therapist"])
    row = conn.execute(
        "SELECT link_id, child_id, therapist FROM therapist_link WHERE device_token_hash = ? AND revoked_at IS NULL", (h,)
    ).fetchone()
    if row:
        return Principal(kind="device", therapist=row["therapist"], link_id=row["link_id"], child_id=row["child_id"])
    raise HTTPException(status_code=401, detail="token tidak dikenal atau akses sudah dicabut")


def require_therapist(conn: sqlite3.Connection, request: Request) -> Principal:
    p = resolve(conn, request)
    if p.kind != "therapist":
        raise HTTPException(status_code=403, detail="hanya terapis")
    return p


def require_device(conn: sqlite3.Connection, request: Request) -> Principal:
    p = resolve(conn, request)
    if p.kind != "device":
        raise HTTPException(status_code=403, detail="hanya perangkat keluarga")
    return p


def therapist_sees_child(conn: sqlite3.Connection, therapist: str, child_id: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM therapist_link WHERE therapist = ? AND child_id = ? AND revoked_at IS NULL LIMIT 1",
        (therapist, child_id),
    ).fetchone()
    return row is not None
