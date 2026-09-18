#!/usr/bin/env python3
"""Pembuat audio bundel papan: satu klip {word_id}.ogg per kata, dari OpenAI TTS.

Dijalankan sekali di laptop. Hasilnya aset statis; aplikasi tetap luring dan tanpa ML saat runtime.

  python3 tools/gen_audio.py --sample              # 12 kata sulit x 8 suara kandidat, untuk dipilih
  python3 tools/gen_audio.py --all                 # 120 kata, suara cowo + cewe terpilih
  python3 tools/gen_audio.py --all --words air,main --force   # ulang kata tertentu saja

Butuh: Python 3.10+, ffmpeg dengan libopus, OPENAI_API_KEY di .env akar repo.
Keluaran di tools/audio_out/ (tidak di-commit). Pemindahan ke assets/ dilakukan setelah disepakati.
"""

import argparse
import csv
import json
import re
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOCAB_CSV = ROOT / "assets" / "vocab" / "core_vocab_id.csv"
OUT_DIR = ROOT / "tools" / "audio_out"

MODEL = "gpt-4o-mini-tts-2025-12-15"  # snapshot dipatok supaya hasil ulang konsisten
API_URL = "https://api.openai.com/v1/audio/speech"

# Suara terpilih untuk --all. Ganti setelah mendengar hasil --sample.
VOICES = {"cowo": "fable", "cewe": "marin"}

# Kandidat untuk --sample.
SAMPLE_VOICES = {"cowo": ["ash", "verse", "echo", "cedar"], "cewe": ["coral", "nova", "shimmer", "marin"]}

# Kata yang paling berisiko salah lafal: ejaan mirip bahasa Inggris, kata informal, satu suku kata, bigram.
SAMPLE_WORDS = ["air", "main", "pup", "ya", "ngaji", "dadah", "pipis", "hape", "angkot", "makasih", "kamar_mandi", "berhenti"]

INSTRUCTIONS = {
    "cowo": (
        "Voice: a friendly Indonesian teenage boy, about 14 years old. "
        "Language: Bahasa Indonesia with standard Indonesian pronunciation; never pronounce the word as English. "
        "Say exactly the given word once and nothing else. "
        "Tone: warm, calm, neutral. Intonation: flat and declarative, not a question, not excited. "
        "Pace: medium. Articulation: clear. No breath or pause before or after."
    ),
    "cewe": (
        "Voice: a friendly Indonesian teenage girl, about 14 years old. "
        "Language: Bahasa Indonesia with standard Indonesian pronunciation; never pronounce the word as English. "
        "Say exactly the given word once and nothing else. "
        "Tone: warm, calm, neutral. Intonation: flat and declarative, not a question, not excited. "
        "Pace: medium. Articulation: clear. No breath or pause before or after."
    ),
}

TARGET_MEAN_DB = -20.0

# Batas biaya lokal. Tarif gpt-4o-mini-tts ~ $0,015 per menit audio keluaran; dikali 2 supaya perkiraan
# selalu di atas tagihan sebenarnya (teks masukan + instruksi ikut ditagih, tapi kecil).
USD_PER_AUDIO_SECOND = 0.015 / 60 * 2
MAX_USD_PER_CALL = 10 * USD_PER_AUDIO_SECOND  # satu kata tidak mungkin > 10 detik
SPEND_FILE = OUT_DIR / "spend.json"
TRIM = "silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.02"


def load_api_key() -> str:
    env = ROOT / ".env"
    if env.exists():
        for line in env.read_text().splitlines():
            m = re.match(r"\s*OPENAI_API_KEY\s*=\s*(.*)\s*$", line)
            if m and m.group(1).strip().strip("'\""):
                return m.group(1).strip().strip("'\"")
    sys.exit("OPENAI_API_KEY kosong. Isi di .env akar repo.")


def load_words() -> dict[str, str]:
    with VOCAB_CSV.open(newline="", encoding="utf-8") as f:
        return {r["word_id"]: r["label_speech"] for r in csv.DictReader(f)}


class Budget:
    """Pengeluaran kumulatif lintas run, disimpan di tools/audio_out/spend.json."""

    def __init__(self, limit: float):
        self.limit = limit
        self.lock = threading.Lock()
        self.spent = json.loads(SPEND_FILE.read_text())["usd_estimated"] if SPEND_FILE.exists() else 0.0
        self.reserved = 0.0

    def reserve(self) -> None:
        with self.lock:
            if self.spent + self.reserved + MAX_USD_PER_CALL > self.limit:
                raise SystemExit(f"Berhenti: batas ${self.limit:.2f} tercapai (terpakai ~${self.spent:.4f}).")
            self.reserved += MAX_USD_PER_CALL

    def settle(self, wav_bytes: int) -> None:
        seconds = max(wav_bytes - 44, 0) / (24000 * 2)  # WAV OpenAI: 24 kHz, 16-bit, mono
        with self.lock:
            self.reserved -= MAX_USD_PER_CALL
            self.spent += seconds * USD_PER_AUDIO_SECOND
            SPEND_FILE.parent.mkdir(parents=True, exist_ok=True)
            SPEND_FILE.write_text(json.dumps({"usd_estimated": round(self.spent, 6)}))


class Pacer:
    """Menjaga jarak antar permintaan supaya tidak melewati batas RPM akun."""

    def __init__(self, rpm: int):
        self.interval = 60.0 / rpm
        self.lock = threading.Lock()
        self.next_at = 0.0

    def wait(self) -> None:
        with self.lock:
            now = time.monotonic()
            start = max(now, self.next_at)
            self.next_at = start + self.interval
        time.sleep(max(0.0, start - now))


PACER = Pacer(9)


def fetch_wav(key: str, text: str, voice: str, instructions: str) -> bytes:
    body = json.dumps(
        {"model": MODEL, "voice": voice, "input": text, "instructions": instructions, "response_format": "wav"}
    ).encode()
    for attempt in range(20):
        PACER.wait()
        req = urllib.request.Request(
            API_URL, data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"}
        )
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            msg = e.read().decode(errors="replace")
            if e.code in (429, 500, 502, 503) and attempt < 19:
                # Batas bergulir: ikuti "try again in Xs" dari OpenAI. Batas harian yang benar-benar habis
                # (menunggu > 2 menit) tidak ditunggu; hentikan saja.
                m = re.search(r"try again in (?:(\d+)m)?([\d.]+)s", msg)
                wait = (int(m.group(1) or 0) * 60 + float(m.group(2))) if m else 10 * (attempt + 1)
                if wait > 120:
                    sys.exit(f"HTTP {e.code}: batas habis, coba lagi dalam {wait / 60:.0f} menit.")
                time.sleep(wait + 1)
                continue
            sys.exit(f"HTTP {e.code} untuk '{text}' ({voice}): {msg[:300]}")
        except (urllib.error.URLError, TimeoutError, ConnectionError) as e:
            if attempt < 19:  # jaringan putus sesaat
                time.sleep(10)
                continue
            sys.exit(f"Jaringan gagal untuk '{text}' ({voice}): {e}")
    raise RuntimeError("tidak tercapai")


def mean_volume(path: Path, pre_filter: str) -> float:
    r = subprocess.run(
        ["ffmpeg", "-hide_banner", "-i", str(path), "-af", f"{pre_filter},volumedetect", "-f", "null", "-"],
        capture_output=True, text=True,
    )
    m = re.search(r"mean_volume:\s*(-?[\d.]+) dB", r.stderr)
    return float(m.group(1)) if m else TARGET_MEAN_DB


def max_volume(path: Path) -> float:
    r = subprocess.run(
        ["ffmpeg", "-hide_banner", "-i", str(path), "-af", "volumedetect", "-f", "null", "-"],
        capture_output=True, text=True,
    )
    m = re.search(r"max_volume:\s*(-?[\d.]+) dB", r.stderr)
    return float(m.group(1)) if m else -99.0


def process(raw: Path, out: Path) -> None:
    """Potong hening depan-belakang, samakan kekerasan, simpan Ogg Opus mono."""
    trim = f"{TRIM},areverse,{TRIM},areverse"
    gain = TARGET_MEAN_DB - mean_volume(raw, trim)
    # Ekor hening 40 ms supaya rangkaian UCAPKAN tidak menempel.
    af = f"{trim},volume={gain:.2f}dB,alimiter=limit=0.9,apad=pad_dur=0.04"
    subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(raw), "-af", af,
         "-ac", "1", "-ar", "48000", "-c:a", "libopus", "-b:a", "32k", str(out)],
        check=True,
    )


def job(key: str, budget: Budget, word_id: str, text: str, voice: str, style: str, out_dir: Path, force: bool) -> str:
    out = out_dir / f"{word_id}.ogg"
    if out.exists() and not force:
        return f"lewati {out.relative_to(ROOT)}"
    raw = out_dir / "raw" / f"{word_id}.wav"
    raw.parent.mkdir(parents=True, exist_ok=True)
    for _ in range(3):
        budget.reserve()
        wav = fetch_wav(key, text, voice, INSTRUCTIONS[style])
        budget.settle(len(wav))
        raw.write_bytes(wav)
        if max_volume(raw) > -40.0:  # model kadang mengembalikan audio hening
            break
    else:
        return f"HENING {out.relative_to(ROOT)} (3x gagal, ulang manual)"
    process(raw, out)
    return f"ok     {out.relative_to(ROOT)}"


def main() -> None:
    ap = argparse.ArgumentParser()
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--sample", action="store_true", help="kata sulit x suara kandidat")
    mode.add_argument("--all", action="store_true", help="120 kata dengan suara terpilih")
    ap.add_argument("--style", choices=["cowo", "cewe", "both"], default="both")
    ap.add_argument("--words", help="daftar word_id dipisah koma (default: semua / kata sampel)")
    ap.add_argument("--force", action="store_true", help="timpa berkas yang sudah ada")
    ap.add_argument("--budget", type=float, default=5.0, help="batas USD kumulatif semua run (default 5)")
    ap.add_argument("--rpm", type=int, default=9, help="batas permintaan per menit (akun ini: 10)")
    ap.add_argument("--workers", type=int, default=3)
    args = ap.parse_args()

    key = load_api_key()
    words = load_words()
    styles = ["cowo", "cewe"] if args.style == "both" else [args.style]
    picked = args.words.split(",") if args.words else (SAMPLE_WORDS if args.sample else list(words))
    unknown = [w for w in picked if w not in words]
    if unknown:
        sys.exit(f"word_id tidak ada di CSV: {', '.join(unknown)}")

    tasks = []
    for style in styles:
        voices = SAMPLE_VOICES[style] if args.sample else [VOICES[style]]
        for voice in voices:
            out_dir = OUT_DIR / ("sample" if args.sample else "final") / (f"{style}-{voice}" if args.sample else style)
            out_dir.mkdir(parents=True, exist_ok=True)
            tasks += [(w, words[w], voice, style, out_dir) for w in picked]

    global PACER
    PACER = Pacer(args.rpm)
    budget = Budget(args.budget)
    worst = len(tasks) * MAX_USD_PER_CALL
    print(f"{len(tasks)} klip, model {MODEL}. Terpakai ~${budget.spent:.4f} dari ${budget.limit:.2f}; "
          f"run ini maksimal ~${worst:.4f}")
    if budget.spent + worst > budget.limit:
        sys.exit("Perkiraan terburuk melewati batas. Kurangi kata/suara atau naikkan --budget.")
    with ThreadPoolExecutor(args.workers) as pool:
        for msg in pool.map(lambda t: job(key, budget, *t, args.force), tasks):
            print(msg)
    print(f"terpakai ~${budget.spent:.4f} (perkiraan atas, kumulatif)")

    manifest = OUT_DIR / ("sample" if args.sample else "final") / "manifest.json"
    manifest.write_text(json.dumps({
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "service": "OpenAI Audio API /v1/audio/speech",
        "model": MODEL,
        "voices": SAMPLE_VOICES if args.sample else VOICES,
        "instructions": INSTRUCTIONS,
        "source_text": "assets/vocab/core_vocab_id.csv kolom label_speech",
        "post_processing": f"ffmpeg: potong hening -45 dB, rata-rata {TARGET_MEAN_DB} dB, limiter 0.9, ekor 40 ms, Opus mono 48 kHz 32 kbps",
        "note": "Suara sintetis buatan AI, bukan rekaman manusia.",
    }, indent=2, ensure_ascii=False))
    print(f"manifest: {manifest.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
