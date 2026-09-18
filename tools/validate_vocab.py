"""Pemeriksaan wajib data kosakata (assets/vocab). Keluar dengan kode 1 bila ada yang gagal.

120 baris · header persis · word_id unik · (page, position_index) unik · halaman 0 = 12 kata inti di posisi 0–11
sesuai susunan tetap · halaman 1–12 tidak memakai posisi 0–5 · jumlah kata per halaman = content_slots_used ·
mirror_word_ids = posisi 0–5 halaman 0 · berkas simbol Mulberry ada.
"""

from __future__ import annotations

import csv
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOCAB = ROOT / "assets" / "vocab" / "core_vocab_id.csv"
PAGES = ROOT / "assets" / "vocab" / "pages.csv"
SYMBOLS = ROOT / "assets" / "symbols"
HEADER = [
    "word_id", "label_display", "label_speech", "pos", "category", "is_core", "page", "position_index",
    "symbol_file", "audio_human_file", "freq_rank", "source_note", "therapist_ok",
]  # fmt: skip
PAGE0 = ["mau", "berhenti", "bantu", "tidak", "selesai", "sakit", "aku", "makan", "minum", "ya", "lagi", "itu"]


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []
    with VOCAB.open(encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        if reader.fieldnames != HEADER:
            errors.append(f"header berbeda: {reader.fieldnames}")
        rows = list(reader)
    with PAGES.open(encoding="utf-8", newline="") as f:
        pages = list(csv.DictReader(f))

    if len(rows) != 120:
        errors.append(f"jumlah baris {len(rows)}, harus 120")
    dup = [w for w, n in Counter(r["word_id"] for r in rows).items() if n > 1]
    if dup:
        errors.append(f"word_id ganda: {dup}")
    slots = Counter((r["page"], r["position_index"]) for r in rows)
    if any(n > 1 for n in slots.values()):
        errors.append(f"(page, position_index) ganda: {[k for k, n in slots.items() if n > 1]}")

    page0 = sorted((r for r in rows if r["page"] == "0"), key=lambda r: int(r["position_index"]))
    if [r["word_id"] for r in page0] != PAGE0 or [int(r["position_index"]) for r in page0] != list(range(12)):
        errors.append(f"halaman 0 tidak sesuai susunan tetap: {[(r['position_index'], r['word_id']) for r in page0]}")

    for r in rows:
        if r["page"] != "0" and int(r["position_index"]) < 6:
            errors.append(f"{r['word_id']}: halaman {r['page']} memakai posisi cermin {r['position_index']}")
        if r["label_display"] != r["label_display"].upper():
            errors.append(f"{r['word_id']}: label_display bukan kapital")
        f = r["symbol_file"]
        path = SYMBOLS / f if f.startswith("custom/") else SYMBOLS / "png" / f
        if not path.exists():
            (warnings if f.startswith("custom/") else errors).append(f"{r['word_id']}: berkas simbol tidak ada ({f})")

    for p in pages:
        n = sum(1 for r in rows if r["page"] == p["page"])
        if n != int(p["content_slots_used"]):
            errors.append(f"halaman {p['page']}: {n} kata, content_slots_used {p['content_slots_used']}")
        if p["page"] != "0" and p["mirror_word_ids"].split() != PAGE0[:6]:
            errors.append(f"halaman {p['page']}: mirror_word_ids {p['mirror_word_ids']!r}")

    for w in warnings:
        print("PERINGATAN", w)
    for e in errors:
        print("GAGAL", e)
    print(f"{'LULUS' if not errors else 'GAGAL'}: {len(rows)} kata, {len(pages)} halaman, {len(warnings)} simbol gambar tim belum ada")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
