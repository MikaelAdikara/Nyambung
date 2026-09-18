"""Server Nyambung: cermin peristiwa perangkat + agregasi untuk papan pantau (kontrak §4).

Jalankan:  NYAMBUNG_THERAPIST_TOKENS="<token≥16>:Bu Rina (ilustratif)" python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
"""

from __future__ import annotations

import json
import os
import sqlite3
import uuid
from datetime import timedelta
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, HTTPException, Query, Request, Response
from fastapi.middleware.cors import CORSMiddleware

from . import auth
from .db import connect, now_utc, parse_utc, transaction, utc_iso
from .schemas import InviteOut, RedeemIn, RedeemOut, SyncIn, SyncOut, TargetIn, TargetOut, parse_device_ts
from .services import summary as agg


def create_app(db_path: Optional[Path | str] = None, therapist_tokens: Optional[str] = None) -> FastAPI:
    conn: sqlite3.Connection = connect(db_path)
    auth.seed_therapists(conn, therapist_tokens if therapist_tokens is not None else os.environ.get("NYAMBUNG_THERAPIST_TOKENS"))

    app = FastAPI(title="Nyambung", version="1.0")
    app.state.conn = conn
    # Dasbor berjalan di port lain dan mengirim Bearer lewat header (tanpa cookie).
    app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

    # Semua endpoint `async def`: berjalan di satu thread event loop, jadi satu koneksi SQLite aman.

    @app.get("/v1/health")
    async def health() -> dict:
        n = conn.execute("SELECT COUNT(*) FROM event").fetchone()[0]
        return {"ok": True, "events": n, "time": utc_iso(now_utc())}

    # ---------- tautan ----------

    @app.post("/v1/link/invite", status_code=201, response_model=InviteOut)
    async def create_invite(request: Request) -> dict:
        p = auth.require_therapist(conn, request)
        with transaction(conn):
            while True:
                code = auth.new_invite_code()
                if not conn.execute("SELECT 1 FROM invite WHERE invite_code = ?", (code,)).fetchone():
                    break
            conn.execute(
                "INSERT INTO invite (invite_code, therapist, created_at) VALUES (?, ?, ?)", (code, p.therapist, utc_iso(now_utc()))
            )
        return {"invite_code": code, "therapist": p.therapist}

    @app.post("/v1/link/redeem", status_code=201, response_model=RedeemOut)
    async def redeem(body: RedeemIn) -> dict:
        code = body.invite_code.strip().upper()
        now = now_utc()
        with transaction(conn):
            inv = conn.execute("SELECT * FROM invite WHERE invite_code = ?", (code,)).fetchone()
            if not inv:
                raise HTTPException(404, "kode undangan tidak dikenal")
            if inv["used_at"] or now - parse_utc(inv["created_at"]) > timedelta(days=auth.INVITE_TTL_DAYS):
                raise HTTPException(410, "kode undangan sudah dipakai atau kedaluwarsa")
            conn.execute("UPDATE invite SET used_at = ? WHERE invite_code = ?", (utc_iso(now), code))
            conn.execute(
                "INSERT INTO child (child_id, nickname, age_years, routine, first_seen_at) VALUES (?, ?, ?, ?, ?) "
                "ON CONFLICT(child_id) DO UPDATE SET nickname = excluded.nickname, age_years = excluded.age_years, "
                "routine = excluded.routine",
                (body.child_id, body.nickname, body.age_years, body.routine, utc_iso(now)),
            )
            token = auth.new_device_token()
            link_id = str(uuid.uuid4())
            linked_at = utc_iso(now)
            conn.execute(
                "INSERT INTO therapist_link (link_id, invite_code, child_id, therapist, linked_at, device_token_hash) "
                "VALUES (?, ?, ?, ?, ?, ?)",
                (link_id, code, body.child_id, inv["therapist"], linked_at, auth.sha256(token)),
            )
        return {"link_id": link_id, "therapist": inv["therapist"], "linked_at": linked_at, "device_token": token}

    @app.delete("/v1/link/{link_id}", status_code=204)
    async def revoke(link_id: str, request: Request) -> Response:
        p = auth.require_device(conn, request)
        if p.link_id != link_id:
            raise HTTPException(403, "bukan tautan perangkat ini")
        with transaction(conn):
            conn.execute("UPDATE therapist_link SET revoked_at = ? WHERE link_id = ? AND revoked_at IS NULL", (utc_iso(now_utc()), link_id))
        return Response(status_code=204)

    # ---------- sinkron ----------

    @app.post("/v1/sync/events", response_model=SyncOut)
    async def sync_events(body: SyncIn, request: Request) -> dict:
        p = auth.require_device(conn, request)
        if p.child_id != body.child_id:
            raise HTTPException(403, "token perangkat untuk anak lain")
        received = utc_iso(now_utc())
        accepted = 0
        with transaction(conn):
            for e in body.events:
                local = parse_device_ts(e.ts_device)
                cur = conn.execute(
                    "INSERT INTO event (event_id, child_id, ts_device, ts_utc, hour_local, date_local, content, method, actor, "
                    "prompt_level, context, session_id, received_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) "
                    "ON CONFLICT(event_id) DO NOTHING",
                    (
                        e.event_id,
                        body.child_id,
                        e.ts_device,
                        utc_iso(local),
                        local.hour,
                        local.date().isoformat(),
                        e.content,
                        e.method,
                        e.actor,
                        e.prompt_level,
                        e.context,
                        e.session_id,
                        received,
                    ),
                )
                accepted += cur.rowcount
            duplicates = len(body.events) - accepted
            conn.execute(
                "INSERT INTO sync_log (child_id, received_at, accepted, duplicates) VALUES (?, ?, ?, ?)",
                (body.child_id, received, accepted, duplicates),
            )
        return {"accepted": accepted, "duplicates": duplicates, "rejected": []}

    # ---------- terapis ----------

    def _therapist_child(request: Request, child_id: str) -> auth.Principal:
        p = auth.require_therapist(conn, request)
        if not auth.therapist_sees_child(conn, p.therapist, child_id):
            raise HTTPException(404, "anak tidak ditemukan")  # jangan bocorkan keberadaan
        return p

    @app.get("/v1/children")
    async def children(request: Request) -> dict:
        p = auth.require_therapist(conn, request)
        return agg.children_overview(conn, therapist=p.therapist)

    @app.get("/v1/children/{child_id}/summary")
    async def child_summary(child_id: str, request: Request, days: int = Query(7, ge=1, le=90)) -> dict:
        p = _therapist_child(request, child_id)
        return agg.summary(conn, child_id, days, therapist=p.therapist)

    @app.post("/v1/children/{child_id}/targets", status_code=201, response_model=TargetOut)
    async def create_target(child_id: str, body: TargetIn, request: Request) -> dict:
        p = _therapist_child(request, child_id)
        target_id = str(uuid.uuid4())
        with transaction(conn):
            conn.execute(
                "INSERT INTO vocab_target (target_id, child_id, words, note, week_index, routine, therapist, created_at) "
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                (target_id, child_id, json.dumps(body.words), body.note, body.week_index, body.routine, p.therapist, utc_iso(now_utc())),
            )
        return next(t for t in agg.target_rows(conn, child_id) if t["target_id"] == target_id)

    @app.get("/v1/children/{child_id}/targets", response_model=list[TargetOut])
    async def list_targets(child_id: str, request: Request) -> list[dict]:
        p = auth.resolve(conn, request)
        if p.kind == "device":
            if p.child_id != child_id:
                raise HTTPException(403, "token perangkat untuk anak lain")
        elif not auth.therapist_sees_child(conn, p.therapist, child_id):
            raise HTTPException(404, "anak tidak ditemukan")
        return agg.target_rows(conn, child_id)

    return app


app = create_app()
