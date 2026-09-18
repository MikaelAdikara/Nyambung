"""Penyedia suara untuk frasa: OpenAI TTS (suara papan) dan ElevenLabs (klon suara keluarga).

Server hanya memanggil penyedia saat frasa **dibuat**. Klip hasilnya diunduh perangkat dan diputar luring, jadi papan
tidak pernah menunggu jaringan. Tanpa kunci API, fitur itu melapor "belum aktif" dan fitur lain tetap jalan.

Rekaman sampel klon diteruskan ke ElevenLabs langsung dari memori dan tidak pernah ditulis ke disk server. Yang
disimpan hanya `voice_id` dari ElevenLabs.

Tanpa dependensi baru: HTTP lewat urllib, multipart disusun tangan.
"""

from __future__ import annotations

import json
import os
import re
import secrets
import urllib.error
import urllib.request
from pathlib import Path
from typing import Optional, Protocol

ROOT = Path(__file__).resolve().parents[3]

OPENAI_URL = "https://api.openai.com/v1/audio/speech"
OPENAI_MODEL = "gpt-4o-mini-tts-2025-12-15"  # sama dengan klip bundel (tools/gen_audio.py)
OPENAI_VOICES = {"cowo": "fable", "cewe": "marin"}
OPENAI_INSTRUCTIONS = {
    "cowo": "Voice: a friendly Indonesian teenage boy, about 14 years old.",
    "cewe": "Voice: a friendly Indonesian teenage girl, about 14 years old.",
}
OPENAI_COMMON = (
    " Language: Bahasa Indonesia with standard Indonesian pronunciation; never pronounce words as English."
    " Say exactly the given text once and nothing else. Tone: warm, calm, clear. Pace: medium, slightly slow."
    " No breath or pause before or after."
)

ELEVEN_BASE = "https://api.elevenlabs.io/v1"
ELEVEN_MODEL = "eleven_multilingual_v2"  # mendukung Bahasa Indonesia


class VoiceError(Exception):
    """Penyedia menolak atau jaringan gagal. `status` dipetakan ke kode HTTP untuk klien."""

    def __init__(self, message: str, status: int = 502):
        super().__init__(message)
        self.status = status


class VoiceProvider(Protocol):
    def available(self) -> dict[str, bool]: ...

    def openai_tts(self, text: str, style: str) -> bytes: ...

    def clone(self, name: str, samples: list[tuple[str, bytes]]) -> str: ...

    def clone_tts(self, voice_id: str, text: str) -> bytes: ...

    def delete_clone(self, voice_id: str) -> None: ...


def _env_key(name: str) -> Optional[str]:
    """Variabel lingkungan dulu, lalu `.env` akar repo, lalu `server/.env`."""
    value = os.environ.get(name, "").strip()
    if value:
        return value
    for env in (ROOT / ".env", ROOT / "server" / ".env"):
        if not env.exists():
            continue
        for line in env.read_text(encoding="utf-8", errors="replace").splitlines():
            m = re.match(rf"\s*{name}\s*=\s*(.*)\s*$", line)
            if m and m.group(1).strip().strip("'\""):
                return m.group(1).strip().strip("'\"")
    return None


def _request(req: urllib.request.Request, timeout: int = 60) -> bytes:
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.read()
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors="replace")[:300]
        if e.code in (401, 403):
            raise VoiceError(f"kunci API ditolak penyedia suara ({e.code})", 502) from e
        if e.code == 429:
            raise VoiceError("penyedia suara sedang membatasi permintaan, coba lagi sebentar", 503) from e
        raise VoiceError(f"penyedia suara menolak permintaan ({e.code}): {detail}", 502) from e
    except (urllib.error.URLError, TimeoutError, ConnectionError) as e:
        raise VoiceError("server tidak bisa menghubungi penyedia suara", 503) from e


def _multipart(fields: dict[str, str], files: list[tuple[str, str, bytes, str]]) -> tuple[bytes, str]:
    boundary = "nyambung" + secrets.token_hex(12)
    parts: list[bytes] = []
    for k, v in fields.items():
        parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{k}"\r\n\r\n{v}\r\n'.encode())
    for field, filename, data, mime in files:
        head = f'--{boundary}\r\nContent-Disposition: form-data; name="{field}"; filename="{filename}"\r\nContent-Type: {mime}\r\n\r\n'
        parts.append(head.encode() + data + b"\r\n")
    parts.append(f"--{boundary}--\r\n".encode())
    return b"".join(parts), f"multipart/form-data; boundary={boundary}"


_MIME = {".m4a": "audio/mp4", ".mp3": "audio/mpeg", ".wav": "audio/wav", ".ogg": "audio/ogg", ".aac": "audio/aac"}


class HttpVoiceProvider:
    """Penyedia sungguhan. Kunci dibaca setiap panggilan supaya mengisi `.env` tidak perlu memulai ulang server."""

    def available(self) -> dict[str, bool]:
        return {"openai": bool(_env_key("OPENAI_API_KEY")), "elevenlabs": bool(_env_key("ELEVENLABS_API_KEY"))}

    def _openai_key(self) -> str:
        key = _env_key("OPENAI_API_KEY")
        if not key:
            raise VoiceError("suara papan untuk frasa belum aktif di server (OPENAI_API_KEY kosong)", 503)
        return key

    def _eleven_key(self) -> str:
        key = _env_key("ELEVENLABS_API_KEY")
        if not key:
            raise VoiceError("klon suara keluarga belum aktif di server (ELEVENLABS_API_KEY kosong)", 503)
        return key

    def openai_tts(self, text: str, style: str) -> bytes:
        body = json.dumps(
            {
                "model": OPENAI_MODEL,
                "voice": OPENAI_VOICES[style],
                "input": text,
                "instructions": OPENAI_INSTRUCTIONS[style] + OPENAI_COMMON,
                "response_format": "mp3",
            }
        ).encode()
        req = urllib.request.Request(
            OPENAI_URL, data=body, headers={"Authorization": f"Bearer {self._openai_key()}", "Content-Type": "application/json"}
        )
        return _request(req)

    def clone(self, name: str, samples: list[tuple[str, bytes]]) -> str:
        files = [("files", fn, data, _MIME.get(Path(fn).suffix.lower(), "application/octet-stream")) for fn, data in samples]
        body, ctype = _multipart(
            {"name": name, "description": "Suara keluarga Nyambung, dibuat atas persetujuan orang tua.", "remove_background_noise": "true"},
            files,
        )
        req = urllib.request.Request(
            f"{ELEVEN_BASE}/voices/add", data=body, headers={"xi-api-key": self._eleven_key(), "Content-Type": ctype}
        )
        data = json.loads(_request(req, timeout=120))
        voice_id = data.get("voice_id")
        if not voice_id:
            raise VoiceError("ElevenLabs tidak mengembalikan voice_id", 502)
        return voice_id

    def clone_tts(self, voice_id: str, text: str) -> bytes:
        body = json.dumps(
            {"text": text, "model_id": ELEVEN_MODEL, "language_code": "id", "voice_settings": {"stability": 0.6, "similarity_boost": 0.85}}
        ).encode()
        req = urllib.request.Request(
            f"{ELEVEN_BASE}/text-to-speech/{voice_id}?output_format=mp3_44100_128",
            data=body,
            headers={"xi-api-key": self._eleven_key(), "Content-Type": "application/json", "Accept": "audio/mpeg"},
        )
        return _request(req)

    def delete_clone(self, voice_id: str) -> None:
        req = urllib.request.Request(f"{ELEVEN_BASE}/voices/{voice_id}", method="DELETE", headers={"xi-api-key": self._eleven_key()})
        try:
            _request(req, timeout=30)
        except VoiceError as e:
            # Suara yang sudah tidak ada di ElevenLabs dianggap terhapus.
            if "(404)" not in str(e) and "(400)" not in str(e):
                raise


# ---------- word_id kartu frasa ----------

FRASA_PREFIX = "frs-"


def phrase_word_id(text: str, phrase_id: str) -> str:
    """`frs-<slug>-<8 hex pertama phrase_id>`. Rumus yang sama ada di aplikasi (`app/lib/data/phrase.dart`) supaya
    ketukan kartu frasa bisa dihitung server tanpa perangkat mengirim pemetaan."""
    slug = re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")[:24].strip("_") or "frasa"
    return f"{FRASA_PREFIX}{slug}-{phrase_id.replace('-', '')[:8]}"
