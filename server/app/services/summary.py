"""Agregasi ringkasan (kontrak §5). Satu definisi, dua implementasi: modul ini dan agregator browser
dasbor mode demo. Angka keduanya HARUS sama untuk data yang sama. Dibekukan di J6.

| Nama | Definisi |
|---|---|
| ketukan | method ∈ {SEL, KAT, PRS} |
| ketukan anak | ketukan dengan actor = anak |
| jendela | [now − days, now) pada ts_utc; unique_words_prev = jendela sebelumnya dengan panjang sama |
| unique_words | jumlah content berbeda pada ketukan anak dalam jendela |
| spontaneous_ratio | ketukan anak spontan / seluruh ketukan anak; null bila 0 |
| missions_done | jumlah date_local berbeda dengan MIS content `selesai` (dalam jendela) |
| missions_skipped | idem dengan `belum_sempat` |
| missions_total | jumlah hari dalam jendela (= days) |
| top_words / word_counts | hitungan content ketukan anak, urut menurun (seri: word_id menaik) |
| hour_histogram | 24 ember dari hour_local ketukan anak |
| weekly_unique_6w | unique_words per pekan (jendela 7 hari mundur dari now) untuk 6 pekan terakhir, terlama dulu |
| trend_3w | w0 = kata unik 7 hari terakhir; w1, w2 = dua pekan sebelumnya. Ambil hanya pekan sebelumnya yang
|            punya data (>0). Tidak ada → `baru`. base = rerata. `naik` bila w0 ≥ base×1,15 dan w0−base ≥ 1;
|            `turun` bila w0 ≤ base×0,85 dan base−w0 ≥ 1; selain itu `tetap` |
| last_sync | MAX(received_at) di sync_log |
| status target | peristiwa TGT terbaru dengan context = target_id: diterima/ditolak; tidak ada → usulan |
| used_count_since_accept | ketukan (semua actor) dengan content ∈ words sejak answered_at, hanya bila diterima |
| pending_targets | jumlah target berstatus usulan |
| linked_weeks | floor(hari sejak linked_at tautan aktif tertua / 7); null bila tidak tertaut |
| needs_review (D1) | last_sync kosong atau > 7 hari, atau trend_3w = turun, atau missions_done ≤ 1 (jendela 7 hari) |
| unsynced_over_7d | jumlah anak yang last_sync kosong atau > 7 hari |

Medan tambahan: total_taps = semua ketukan dalam jendela; parent_taps / child_taps per actor;
prompted_taps / spontaneous_taps = ketukan anak per prompt_level; missions_done_6w / missions_skipped di
jendela 42 hari dengan missions_total_6w = 42.

Semua angka ini adalah pola pemakaian, bukan ukuran kemampuan anak.
"""

from __future__ import annotations

import json
import sqlite3
from collections import Counter
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Iterable, Optional

from ..db import now_utc, parse_utc, utc_iso

TAP_METHODS = frozenset({"SEL", "KAT", "PRS"})
WEEK = timedelta(days=7)


@dataclass(frozen=True)
class Ev:
    ts_utc: str
    date_local: str
    hour_local: int
    content: str
    method: str
    actor: str
    prompt_level: str
    context: Optional[str]


def _events(conn: sqlite3.Connection, child_id: str) -> list[Ev]:
    rows = conn.execute(
        "SELECT ts_utc, date_local, hour_local, content, method, actor, prompt_level, context "
        "FROM event WHERE child_id = ? ORDER BY ts_utc",
        (child_id,),
    ).fetchall()
    return [Ev(**dict(r)) for r in rows]


def _in(ev: Ev, start: str, end: str) -> bool:
    return start <= ev.ts_utc < end


def _window(now: datetime, days: int, offset_days: int = 0) -> tuple[str, str]:
    end = now - timedelta(days=offset_days)
    return utc_iso(end - timedelta(days=days)), utc_iso(end)


def child_taps(evs: Iterable[Ev]) -> list[Ev]:
    return [e for e in evs if e.method in TAP_METHODS and e.actor == "anak"]


def unique_words(evs: list[Ev], start: str, end: str) -> int:
    return len({e.content for e in child_taps(evs) if _in(e, start, end)})


def mission_days(evs: list[Ev], start: str, end: str, content: str) -> int:
    return len({e.date_local for e in evs if e.method == "MIS" and e.content == content and _in(e, start, end)})


def trend_3w(evs: list[Ev], now: datetime) -> str:
    w0 = unique_words(evs, *_window(now, 7))
    prev = [unique_words(evs, *_window(now, 7, 7 * k)) for k in (1, 2)]
    prev = [w for w in prev if w > 0]
    if not prev:
        return "baru"
    base = sum(prev) / len(prev)
    if w0 >= base * 1.15 and w0 - base >= 1:
        return "naik"
    if w0 <= base * 0.85 and base - w0 >= 1:
        return "turun"
    return "tetap"


def last_sync(conn: sqlite3.Connection, child_id: str) -> Optional[str]:
    row = conn.execute("SELECT MAX(received_at) AS t FROM sync_log WHERE child_id = ?", (child_id,)).fetchone()
    return row["t"] if row else None


def target_rows(conn: sqlite3.Connection, child_id: str, evs: Optional[list[Ev]] = None) -> list[dict]:
    """Target anak, terbaru dulu, dengan status yang diturunkan dari peristiwa TGT."""
    evs = evs if evs is not None else _events(conn, child_id)
    rows = conn.execute(
        "SELECT * FROM vocab_target WHERE child_id = ? ORDER BY created_at DESC, target_id DESC", (child_id,)
    ).fetchall()
    out = []
    for r in rows:
        words = json.loads(r["words"])
        answers = [e for e in evs if e.method == "TGT" and e.context == r["target_id"]]
        status, answered_at, used = "usulan", None, 0
        if answers:
            last = answers[-1]
            status = last.content if last.content in ("diterima", "ditolak") else "usulan"
            answered_at = last.ts_utc
            if status == "diterima":
                used = sum(1 for e in evs if e.method in TAP_METHODS and e.content in words and e.ts_utc >= answered_at)
        out.append(
            {
                "target_id": r["target_id"],
                "child_id": r["child_id"],
                "words": words,
                "note": r["note"],
                "week_index": r["week_index"],
                "routine": r["routine"],
                "therapist": r["therapist"],
                "created_at": r["created_at"],
                "status": status,
                "answered_at": answered_at,
                "used_count_since_accept": used,
            }
        )
    return out


def linked_weeks(conn: sqlite3.Connection, child_id: str, now: datetime, therapist: Optional[str] = None) -> Optional[int]:
    q = "SELECT MIN(linked_at) AS t FROM therapist_link WHERE child_id = ? AND revoked_at IS NULL"
    args: list = [child_id]
    if therapist:
        q += " AND therapist = ?"
        args.append(therapist)
    row = conn.execute(q, args).fetchone()
    if not row or not row["t"]:
        return None
    return max(0, (now - parse_utc(row["t"])).days // 7)


def _stale(sync: Optional[str], now: datetime) -> bool:
    return sync is None or now - parse_utc(sync) > WEEK


def summary(conn: sqlite3.Connection, child_id: str, days: int = 7, now: Optional[datetime] = None, therapist: Optional[str] = None) -> dict:
    now = now or now_utc()
    child = conn.execute("SELECT * FROM child WHERE child_id = ?", (child_id,)).fetchone()
    evs = _events(conn, child_id)
    start, end = _window(now, days)
    pstart, pend = _window(now, days, days)

    taps = [e for e in evs if e.method in TAP_METHODS and _in(e, start, end)]
    kid = [e for e in taps if e.actor == "anak"]
    spont = sum(1 for e in kid if e.prompt_level == "spontan")
    counts = Counter(e.content for e in kid)
    ordered = sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))
    hist = [0] * 24
    for e in kid:
        hist[e.hour_local] += 1

    s6, e6 = _window(now, 42)
    targets = target_rows(conn, child_id, evs)
    return {
        "child_id": child_id,
        "nickname": child["nickname"] if child else None,
        "age_years": child["age_years"] if child else None,
        "routine": child["routine"] if child else None,
        "days": days,
        "window_start_utc": start,
        "window_end_utc": end,
        "unique_words": len(counts),
        "unique_words_prev": unique_words(evs, pstart, pend),
        "spontaneous_ratio": (spont / len(kid)) if kid else None,
        "missions_done": mission_days(evs, start, end, "selesai"),
        "missions_total": days,
        "top_words": [{"word": w, "count": c} for w, c in ordered[:10]],
        "hour_histogram": hist,
        "last_sync": last_sync(conn, child_id),
        "trend_3w": trend_3w(evs, now),
        "total_taps": len(taps),
        "parent_taps": sum(1 for e in taps if e.actor == "pendamping"),
        "child_taps": len(kid),
        "prompted_taps": len(kid) - spont,
        "spontaneous_taps": spont,
        "missions_skipped": mission_days(evs, start, end, "belum_sempat"),
        "weekly_unique_6w": [unique_words(evs, *_window(now, 7, 7 * k)) for k in range(5, -1, -1)],
        "missions_done_6w": mission_days(evs, s6, e6, "selesai"),
        "missions_total_6w": 42,
        "word_counts": dict(ordered),
        "linked_weeks": linked_weeks(conn, child_id, now, therapist),
        "pending_targets": sum(1 for t in targets if t["status"] == "usulan"),
    }


def children_overview(conn: sqlite3.Connection, now: Optional[datetime] = None, therapist: Optional[str] = None) -> dict:
    """D1: anak yang tertaut (aktif) ke terapis ini, atau semua anak bila `therapist` None."""
    now = now or now_utc()
    if therapist:
        ids = [
            r["child_id"]
            for r in conn.execute(
                "SELECT DISTINCT child_id FROM therapist_link WHERE therapist = ? AND revoked_at IS NULL", (therapist,)
            )
        ]
    else:
        ids = [r["child_id"] for r in conn.execute("SELECT child_id FROM child")]
    children = []
    for cid in ids:
        s = summary(conn, cid, 7, now, therapist)
        needs = _stale(s["last_sync"], now) or s["trend_3w"] == "turun" or s["missions_done"] <= 1
        children.append(
            {
                "child_id": cid,
                "nickname": s["nickname"],
                "age_years": s["age_years"],
                "routine": s["routine"],
                "unique_words": s["unique_words"],
                "trend_3w": s["trend_3w"],
                "missions_done": s["missions_done"],
                "missions_total": s["missions_total"],
                "last_sync": s["last_sync"],
                "pending_targets": s["pending_targets"],
                "needs_review": needs,
            }
        )
    children.sort(key=lambda c: (not c["needs_review"], (c["nickname"] or "").lower()))
    return {
        "active_families": len(children),
        "needs_review": sum(1 for c in children if c["needs_review"]),
        "unsynced_over_7d": sum(1 for c in children if _stale(c["last_sync"], now)),
        "pending_targets": sum(c["pending_targets"] for c in children),
        "children": children,
    }
