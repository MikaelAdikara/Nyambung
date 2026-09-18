from __future__ import annotations

import asyncio
import base64
import binascii
import io
import json
import sqlite3
import threading
import uuid
from datetime import timedelta

from fastapi import FastAPI, HTTPException, Request
from PIL import Image, ImageOps, UnidentifiedImageError
from pydantic import ValidationError

from .. import auth
from ..db import now_utc, transaction, utc_iso
from ..scene_schemas import SceneAnalyzeIn, SceneAnalyzeOut
from ..services.scene_ai import SceneVisionError, SceneVisionProvider

MAX_HOTSPOTS = 6
MAX_BODY_BYTES = 4 * 1024 * 1024
MAX_IMAGE_BYTES = 2 * 1024 * 1024
MAX_PIXELS = 1_638_400
MAX_REQUESTS_DAY = 10


def register_scene_ai_routes(app: FastAPI, conn: sqlite3.Connection, provider: SceneVisionProvider) -> None:
    active: set[str] = set()
    active_lock = threading.Lock()

    def require_child(request: Request, child_id: str) -> None:
        principal = auth.require_device(conn, request)
        if principal.child_id != child_id:
            raise HTTPException(403, "token perangkat untuk anak lain")

    @app.get("/v1/children/{child_id}/scene-ai/status")
    async def scene_ai_status(child_id: str, request: Request) -> dict:
        require_child(request, child_id)
        name = provider.name() if hasattr(provider, "name") else "google"
        return {"available": provider.available(), "provider": name, "max_hotspots": MAX_HOTSPOTS}

    @app.post("/v1/children/{child_id}/scene-ai/analyze", response_model=SceneAnalyzeOut)
    async def analyze_scene(child_id: str, request: Request) -> dict:
        require_child(request, child_id)
        content_length = request.headers.get("content-length")
        if content_length is not None:
            try:
                if int(content_length) > MAX_BODY_BYTES:
                    raise HTTPException(413, "permintaan terlalu besar")
            except ValueError as exc:
                raise HTTPException(400, "Content-Length tidak sah") from exc
        chunks = bytearray()
        async for chunk in request.stream():
            chunks.extend(chunk)
            if len(chunks) > MAX_BODY_BYTES:
                raise HTTPException(413, "permintaan terlalu besar")
        try:
            decoded = json.loads(chunks)
            body = SceneAnalyzeIn.model_validate(decoded)
        except (json.JSONDecodeError, UnicodeDecodeError, ValidationError, TypeError) as exc:
            raise HTTPException(422, "permintaan analisis foto tidak sah") from exc
        try:
            image_bytes = base64.b64decode(body.image_base64, validate=True)
        except (binascii.Error, ValueError) as exc:
            raise HTTPException(422, "foto bukan base64 yang sah") from exc
        if len(image_bytes) > MAX_IMAGE_BYTES:
            raise HTTPException(413, "foto terlalu besar")
        try:
            with Image.open(io.BytesIO(image_bytes)) as source:
                source.verify()
            with Image.open(io.BytesIO(image_bytes)) as source:
                oriented = ImageOps.exif_transpose(source).convert("RGB")
                width, height = oriented.size
                if width <= 0 or height <= 0 or width * height > MAX_PIXELS or width > 1280 or height > 1280:
                    raise HTTPException(422, "dimensi foto tidak didukung")
                clean = io.BytesIO()
                oriented.save(clean, format="JPEG", quality=88, optimize=True)
                clean_bytes = clean.getvalue()
        except HTTPException:
            raise
        except (UnidentifiedImageError, OSError, Image.DecompressionBombError) as exc:
            raise HTTPException(422, "foto JPEG rusak") from exc
        if not provider.available():
            raise HTTPException(503, "bantuan AI belum aktif di server")
        with active_lock:
            if child_id in active:
                raise HTTPException(429, "analisis foto lain masih berjalan")
            active.add(child_id)
        request_id = str(uuid.uuid4())
        try:
            since = utc_iso(now_utc() - timedelta(days=1))
            with transaction(conn):
                count = conn.execute(
                    "SELECT COUNT(*) FROM scene_ai_attempt WHERE child_id = ? AND started_at >= ?", (child_id, since)
                ).fetchone()[0]
                if count >= MAX_REQUESTS_DAY:
                    raise HTTPException(429, "batas analisis foto harian tercapai")
                conn.execute(
                    "INSERT INTO scene_ai_attempt(request_id, child_id, started_at) VALUES (?, ?, ?)",
                    (request_id, child_id, utc_iso(now_utc())),
                )
            symbols = [item.model_dump() for item in body.allowed_symbols]
            allowed_ids = {item["word_id"] for item in symbols}
            try:
                raw = await asyncio.wait_for(asyncio.to_thread(provider.analyze, clean_bytes, symbols), timeout=30)
            except asyncio.TimeoutError as exc:
                raise HTTPException(504, "analisis foto melewati batas waktu") from exc
            except SceneVisionError as exc:
                raise HTTPException(502, str(exc)) from exc
            model = raw.get("model")
            candidates = raw.get("candidates")
            if not isinstance(model, str) or not isinstance(candidates, list):
                raise HTTPException(502, "respons provider vision tidak sah")
            output = []
            for candidate in candidates[:MAX_HOTSPOTS]:
                try:
                    label = str(candidate["observed_label"]).strip()[:60]
                    word_id = candidate.get("word_id")
                    y0, x0, y1, x1 = [float(v) for v in candidate["box_1000"]]
                except (KeyError, TypeError, ValueError) as exc:
                    raise HTTPException(502, "kandidat provider vision tidak sah") from exc
                if not label or (word_id is not None and word_id not in allowed_ids) or not (0 <= x0 < x1 <= 1000 and 0 <= y0 < y1 <= 1000):
                    raise HTTPException(502, "kandidat provider vision tidak sah")
                output.append(
                    {
                        "id": str(uuid.uuid4()),
                        "observed_label": label,
                        "word_id": word_id,
                        "box": {"x": x0 / 1000, "y": y0 / 1000, "width": (x1 - x0) / 1000, "height": (y1 - y0) / 1000},
                    }
                )
            return {
                "request_id": request_id,
                "provider": raw.get("provider") if raw.get("provider") in ("google", "openai") else "google",
                "model": model,
                "image_width": width,
                "image_height": height,
                "candidates": output,
                "warnings": [],
            }
        finally:
            with active_lock:
                active.discard(child_id)
