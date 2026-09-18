"""Server Nyambung: cermin peristiwa perangkat + agregasi untuk papan pantau (kontrak §4).

Jalankan:  NYAMBUNG_THERAPIST_TOKENS="<token≥16>:Bu Rina (ilustratif)" python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
"""

from __future__ import annotations

import asyncio
import base64
import binascii
import json
import os
import sqlite3
import uuid
from datetime import timedelta
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, HTTPException, Query, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse

from . import auth
from .db import connect, db_path as default_db_path, now_utc, parse_utc, transaction, utc_iso
from .schemas import (
    CloneIn,
    InviteOut,
    LoginIn,
    LoginOut,
    MeOut,
    PhraseIn,
    PhraseOut,
    RedeemIn,
    RedeemOut,
    ReviewTimeIn,
    SessionNoteIn,
    SessionNoteOut,
    SessionShareIn,
    SharedSummaryOut,
    SyncIn,
    SyncOut,
    TargetIn,
    TargetOut,
    VoiceStatusOut,
    parse_device_ts,
)
from .services import summary as agg
from .services.voice import HttpVoiceProvider, VoiceError, VoiceProvider

# Batas pembuatan frasa per anak per hari: menahan biaya penyedia suara bila ada klien yang berulang.
PHRASES_PER_DAY = 30


def create_app(
    db_path: Optional[Path | str] = None, therapist_tokens: Optional[str] = None, voice: Optional[VoiceProvider] = None
) -> FastAPI:
    conn: sqlite3.Connection = connect(db_path)
    voices: VoiceProvider = voice or HttpVoiceProvider()
    # Klip frasa disimpan di samping berkas basis data (server/data/phrases/), tidak di-commit.
    phrase_dir = Path(db_path if db_path is not None else default_db_path()).parent / "phrases"
    phrase_dir.mkdir(parents=True, exist_ok=True)
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

    # ---------- login terapis ----------

    @app.post("/v1/auth/login", response_model=LoginOut)
    async def login(body: LoginIn) -> dict:
        with transaction(conn):
            session = auth.login(conn, body.email, body.password)
        if not session:
            raise HTTPException(401, "email atau kata sandi salah")
        return session

    @app.post("/v1/auth/logout", status_code=204)
    async def logout(request: Request) -> Response:
        auth.require_therapist(conn, request)
        with transaction(conn):
            auth.logout(conn, request)
        return Response(status_code=204)

    @app.get("/v1/auth/me", response_model=MeOut)
    async def me(request: Request) -> dict:
        p = auth.require_therapist(conn, request)
        return {"therapist": p.therapist, "email": auth.therapist_email(conn, p.therapist)}

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

    @app.get("/v1/children/{child_id}/missions")
    async def missions(child_id: str, request: Request, days: int = Query(14, ge=1, le=90)) -> list[dict]:
        _therapist_child(request, child_id)
        return agg.mission_rows(conn, child_id, days)

    # ---------- catatan sesi (D4) ----------

    def _own_note(child_id: str, note_id: str, therapist: str) -> sqlite3.Row:
        row = conn.execute(
            "SELECT * FROM session_note WHERE note_id = ? AND child_id = ? AND therapist = ?", (note_id, child_id, therapist)
        ).fetchone()
        if not row:
            raise HTTPException(404, "catatan tidak ditemukan")
        return row

    @app.get("/v1/children/{child_id}/sessions", response_model=list[SessionNoteOut])
    async def list_sessions(child_id: str, request: Request) -> list[dict]:
        p = _therapist_child(request, child_id)
        return agg.session_rows(conn, child_id, p.therapist)

    @app.post("/v1/children/{child_id}/sessions", status_code=201, response_model=SessionNoteOut)
    async def create_session(child_id: str, body: SessionNoteIn, request: Request) -> dict:
        p = _therapist_child(request, child_id)
        note_id = str(uuid.uuid4())
        now = utc_iso(now_utc())
        with transaction(conn):
            conn.execute(
                "INSERT INTO session_note (note_id, child_id, therapist, session_date, note, focus, next_session, created_at, "
                "updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                (note_id, child_id, p.therapist, body.session_date, body.note, body.focus, body.next_session, now, now),
            )
        return dict(_own_note(child_id, note_id, p.therapist))

    @app.put("/v1/children/{child_id}/sessions/{note_id}", response_model=SessionNoteOut)
    async def update_session(child_id: str, note_id: str, body: SessionNoteIn, request: Request) -> dict:
        p = _therapist_child(request, child_id)
        _own_note(child_id, note_id, p.therapist)
        with transaction(conn):
            conn.execute(
                "UPDATE session_note SET session_date = ?, note = ?, focus = ?, next_session = ?, updated_at = ? WHERE note_id = ?",
                (body.session_date, body.note, body.focus, body.next_session, utc_iso(now_utc()), note_id),
            )
        return dict(_own_note(child_id, note_id, p.therapist))

    @app.post("/v1/children/{child_id}/sessions/{note_id}/share", response_model=SessionNoteOut)
    async def share_session(child_id: str, note_id: str, body: SessionShareIn, request: Request) -> dict:
        """Kirim ringkasan ke keluarga. Hanya `family_text` yang sampai ke perangkat; catatan sesi tetap milik terapis."""
        p = _therapist_child(request, child_id)
        _own_note(child_id, note_id, p.therapist)
        with transaction(conn):
            conn.execute(
                "UPDATE session_note SET family_text = ?, shared_at = ? WHERE note_id = ?",
                (body.family_text.strip(), utc_iso(now_utc()), note_id),
            )
        return dict(_own_note(child_id, note_id, p.therapist))

    @app.get("/v1/children/{child_id}/shared-summaries", response_model=list[SharedSummaryOut])
    async def shared_summaries(child_id: str, request: Request) -> list[dict]:
        p = auth.require_device(conn, request)
        if p.child_id != child_id:
            raise HTTPException(403, "token perangkat untuk anak lain")
        return agg.shared_summary_rows(conn, child_id)

    # ---------- suara & frasa ----------

    def _child_access(request: Request, child_id: str) -> auth.Principal:
        """Perangkat milik anak ini, atau terapis yang tertaut dengannya."""
        p = auth.resolve(conn, request)
        if p.kind == "device":
            if p.child_id != child_id:
                raise HTTPException(403, "token perangkat untuk anak lain")
        elif not auth.therapist_sees_child(conn, p.therapist, child_id):
            raise HTTPException(404, "anak tidak ditemukan")
        return p

    def _active_clone(child_id: str) -> Optional[sqlite3.Row]:
        return conn.execute(
            "SELECT * FROM voice_clone WHERE child_id = ? AND revoked_at IS NULL AND voice_id IS NOT NULL", (child_id,)
        ).fetchone()

    def _voice_status(child_id: str) -> dict:
        clone = _active_clone(child_id)
        return {
            **voices.available(),
            "clone_active": clone is not None,
            "clone_consent_by": clone["consent_by"] if clone else None,
            "clone_consent_at": clone["consent_at"] if clone else None,
        }

    async def _call(fn, *args):
        """Panggilan penyedia di thread lain supaya server tetap melayani permintaan lain selama menunggu."""
        try:
            return await asyncio.to_thread(fn, *args)
        except VoiceError as e:
            raise HTTPException(e.status, str(e)) from e

    @app.get("/v1/children/{child_id}/voice", response_model=VoiceStatusOut)
    async def voice_status(child_id: str, request: Request) -> dict:
        _child_access(request, child_id)
        return _voice_status(child_id)

    @app.post("/v1/children/{child_id}/voice/clone", response_model=VoiceStatusOut)
    async def create_clone(child_id: str, body: CloneIn, request: Request) -> dict:
        """Hanya perangkat keluarga, dengan persetujuan eksplisit. Sampel diteruskan dari memori, tidak disimpan."""
        p = auth.require_device(conn, request)
        if p.child_id != child_id:
            raise HTTPException(403, "token perangkat untuk anak lain")
        try:
            samples = [(s.filename, base64.b64decode(s.data_b64, validate=True)) for s in body.samples]
        except (binascii.Error, ValueError) as e:
            raise HTTPException(422, "sampel suara bukan base64 yang sah") from e
        # Nama di ElevenLabs tidak memuat nama anak.
        voice_id = await _call(voices.clone, f"Nyambung keluarga {child_id.replace('-', '')[:8]}", samples)
        old = _active_clone(child_id)
        with transaction(conn):
            conn.execute(
                "INSERT INTO voice_clone (child_id, voice_id, consent_by, consent_at, revoked_at) VALUES (?, ?, ?, ?, NULL) "
                "ON CONFLICT(child_id) DO UPDATE SET voice_id = excluded.voice_id, consent_by = excluded.consent_by, "
                "consent_at = excluded.consent_at, revoked_at = NULL",
                (child_id, voice_id, body.consent_by.strip(), utc_iso(now_utc())),
            )
        if old and old["voice_id"] != voice_id:
            try:
                await asyncio.to_thread(voices.delete_clone, old["voice_id"])
            except VoiceError:
                pass  # suara lama tetap tidak dipakai lagi; penghapusan bisa diulang dari ElevenLabs
        return _voice_status(child_id)

    @app.delete("/v1/children/{child_id}/voice/clone", response_model=VoiceStatusOut)
    async def revoke_clone(child_id: str, request: Request) -> dict:
        """Orang tua mencabut klon: suara dihapus di ElevenLabs, lalu frasa baru dengan suara keluarga ditolak.
        Klip yang sudah diunduh ke perangkat tetap di perangkat dan dikelola keluarga."""
        p = auth.require_device(conn, request)
        if p.child_id != child_id:
            raise HTTPException(403, "token perangkat untuk anak lain")
        clone = _active_clone(child_id)
        if clone:
            await _call(voices.delete_clone, clone["voice_id"])
            with transaction(conn):
                conn.execute(
                    "UPDATE voice_clone SET voice_id = NULL, revoked_at = ? WHERE child_id = ?", (utc_iso(now_utc()), child_id)
                )
        return _voice_status(child_id)

    @app.get("/v1/children/{child_id}/phrases", response_model=list[PhraseOut])
    async def list_phrases(child_id: str, request: Request) -> list[dict]:
        _child_access(request, child_id)
        return agg.phrase_rows(conn, child_id)

    @app.post("/v1/children/{child_id}/phrases", status_code=201, response_model=PhraseOut)
    async def create_phrase(child_id: str, body: PhraseIn, request: Request) -> dict:
        p = _child_access(request, child_id)
        since = utc_iso(now_utc() - timedelta(days=1))
        made = conn.execute("SELECT COUNT(*) FROM phrase WHERE child_id = ? AND created_at >= ?", (child_id, since)).fetchone()[0]
        if made >= PHRASES_PER_DAY:
            raise HTTPException(429, f"batas {PHRASES_PER_DAY} frasa per hari untuk anak ini tercapai")
        if body.voice == "keluarga":
            clone = _active_clone(child_id)
            if not clone:
                raise HTTPException(409, "suara keluarga belum diaktifkan orang tua")
            audio = await _call(voices.clone_tts, clone["voice_id"], body.text)
        else:
            audio = await _call(voices.openai_tts, body.text, body.voice)
        if len(audio) < 100:
            raise HTTPException(502, "penyedia suara mengembalikan audio kosong")
        phrase_id = str(uuid.uuid4())
        audio_file = f"{phrase_id}.mp3"
        (phrase_dir / audio_file).write_bytes(audio)
        with transaction(conn):
            conn.execute(
                "INSERT INTO phrase (phrase_id, child_id, text, voice, created_by, created_at, audio_file) VALUES (?, ?, ?, ?, ?, ?, ?)",
                (
                    phrase_id,
                    child_id,
                    body.text,
                    body.voice,
                    "keluarga" if p.kind == "device" else p.therapist,
                    utc_iso(now_utc()),
                    audio_file,
                ),
            )
        return next(r for r in agg.phrase_rows(conn, child_id) if r["phrase_id"] == phrase_id)

    @app.get("/v1/children/{child_id}/phrases/{phrase_id}/audio")
    async def phrase_audio(child_id: str, phrase_id: str, request: Request) -> FileResponse:
        _child_access(request, child_id)
        row = conn.execute("SELECT audio_file FROM phrase WHERE phrase_id = ? AND child_id = ?", (phrase_id, child_id)).fetchone()
        path = phrase_dir / row["audio_file"] if row else None
        if not path or not path.is_file():
            raise HTTPException(404, "klip frasa tidak ditemukan")
        return FileResponse(path, media_type="audio/mpeg")

    # ---------- waktu tinjauan (D1) ----------

    @app.post("/v1/review-time", status_code=204)
    async def review_time(body: ReviewTimeIn, request: Request) -> Response:
        p = _therapist_child(request, body.child_id)
        with transaction(conn):
            conn.execute(
                "INSERT INTO review_log (therapist, child_id, seconds, recorded_at) VALUES (?, ?, ?, ?)",
                (p.therapist, body.child_id, body.seconds, utc_iso(now_utc())),
            )
        return Response(status_code=204)

    return app


app = create_app()
