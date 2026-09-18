"""Autentikasi Bearer (kontrak §4). Server hanya menyimpan SHA-256 token.

- Terapis: token dari env `NYAMBUNG_THERAPIST_TOKENS="tokA:Bu Rina (ilustratif);tokB:Pak Dimas"`, ≥ 16 karakter.
- Terapis (login): email + kata sandi (scrypt) → token sesi 30 hari di `therapist_session`. Akun dibuat lewat
  `tools/create_therapist.py`, tidak ada pendaftaran terbuka.
- Perangkat: token dikeluarkan sekali saat `redeem`, berlaku untuk `child_id` tautannya saja.
"""

from __future__ import annotations

import hashlib
import logging
import secrets
import sqlite3
from dataclasses import dataclass
from datetime import timedelta
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


# ---------- login email + kata sandi terapis ----------

MIN_PASSWORD_LEN = 8
SESSION_TTL_DAYS = 30
# scrypt dari stdlib: tanpa dependensi baru. N=2^14, r=8, p=1 (±16 MB, ±50 ms per percobaan).
_SCRYPT_N, _SCRYPT_R, _SCRYPT_P = 2**14, 8, 1


def normalize_email(email: str) -> str:
    return email.strip().lower()


def hash_password(password: str) -> str:
    salt = secrets.token_bytes(16)
    digest = hashlib.scrypt(password.encode("utf-8"), salt=salt, n=_SCRYPT_N, r=_SCRYPT_R, p=_SCRYPT_P, dklen=32)
    return f"scrypt${_SCRYPT_N}${_SCRYPT_R}${_SCRYPT_P}${salt.hex()}${digest.hex()}"


def verify_password(password: str, stored: str) -> bool:
    try:
        algo, n, r, p, salt_hex, digest_hex = stored.split("$")
        if algo != "scrypt":
            return False
        digest = hashlib.scrypt(
            password.encode("utf-8"), salt=bytes.fromhex(salt_hex), n=int(n), r=int(r), p=int(p), dklen=len(digest_hex) // 2
        )
    except ValueError:
        return False
    return secrets.compare_digest(digest.hex(), digest_hex)


# Dipakai saat email tidak dikenal supaya waktu jawab sama dengan kata sandi salah (tidak membocorkan email).
_DUMMY_HASH = hash_password("tidak-ada-akun-ini")


def create_therapist_login(conn: sqlite3.Connection, email: str, therapist: str, password: str) -> None:
    """Buat akun login terapis. ValueError bila email tidak wajar, kata sandi pendek, atau email/nama sudah ada."""
    email = normalize_email(email)
    therapist = therapist.strip()
    if "@" not in email or email.startswith("@") or email.endswith("@") or len(email) > 254:
        raise ValueError("email tidak wajar")
    if len(password) < MIN_PASSWORD_LEN:
        raise ValueError(f"kata sandi minimal {MIN_PASSWORD_LEN} karakter")
    if not therapist:
        raise ValueError("nama terapis kosong")
    try:
        conn.execute(
            "INSERT INTO therapist_login (email, therapist, password_hash, created_at) VALUES (?, ?, ?, ?)",
            (email, therapist, hash_password(password), utc_iso(now_utc())),
        )
    except sqlite3.IntegrityError as e:
        raise ValueError("email atau nama terapis sudah terdaftar") from e


def login(conn: sqlite3.Connection, email: str, password: str) -> Optional[dict]:
    """Email + kata sandi benar → sesi baru `{token, therapist, expires_at}`; salah → None."""
    row = conn.execute("SELECT therapist, password_hash FROM therapist_login WHERE email = ?", (normalize_email(email),)).fetchone()
    ok = verify_password(password, row["password_hash"] if row else _DUMMY_HASH)
    if not row or not ok:
        return None
    token = secrets.token_urlsafe(32)
    now = now_utc()
    expires_at = utc_iso(now + timedelta(days=SESSION_TTL_DAYS))
    conn.execute(
        "INSERT INTO therapist_session (token_hash, therapist, created_at, expires_at) VALUES (?, ?, ?, ?)",
        (sha256(token), row["therapist"], utc_iso(now), expires_at),
    )
    return {"token": token, "therapist": row["therapist"], "expires_at": expires_at}


def logout(conn: sqlite3.Connection, request: Request) -> None:
    conn.execute("DELETE FROM therapist_session WHERE token_hash = ?", (sha256(_bearer(request)),))


def therapist_email(conn: sqlite3.Connection, therapist: str) -> Optional[str]:
    row = conn.execute("SELECT email FROM therapist_login WHERE therapist = ?", (therapist,)).fetchone()
    return row["email"] if row else None


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
        "SELECT therapist FROM therapist_session WHERE token_hash = ? AND expires_at > ?", (h, utc_iso(now_utc()))
    ).fetchone()
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
