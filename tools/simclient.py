"""Perangkat tiruan Nyambung (Python murni, tanpa dependensi).

Memakai skema perangkat yang sama dengan aplikasi (`app/lib/data/db/schema.sql`: log append-only + outbox
dalam satu transaksi) dan urutan sinkron yang sama: ambil batch 40 dari outbox → POST → **hanya bila 200**
isi `synced_at` dan hapus outbox.

Perintah:
  demo   --days 21            lima keluarga ilustratif, undang → tebus → peristiwa → sinkron → seed/demo_events.json
  sync   --child X [--crash-after N]   kirim outbox; --crash-after mematikan proses (137) SETELAH server menjawab
                                        200 untuk batch ke-N dan SEBELUM outbox lokal dibersihkan
  verify --child X            bandingkan event_id lokal dengan server → identical: true/false
  tap    --child X --n 10     tambah ketukan anak ke perangkat tiruan (untuk uji crash)

Alamat bawaan http://127.0.0.1:8000. Terapis: --email + --password (login), --token, atau token pertama di
NYAMBUNG_THERAPIST_TOKENS. --out mengganti tujuan berkas seed (bawaan seed/demo_events.json).
Semua data yang dihasilkan ILUSTRATIF.
"""

from __future__ import annotations

import argparse
import json
import os
import random
import sqlite3
import sys
import urllib.error
import urllib.request
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCHEMA_SQL = ROOT / "app" / "lib" / "data" / "db" / "schema.sql"
SIM_DIR = Path(__file__).resolve().parent / ".sim"
SEED_OUT = ROOT / "seed" / "demo_events.json"
DEFAULT_SERVER = "http://127.0.0.1:8000"
DEFAULT_SERVER_DB = ROOT / "server" / "data" / "nyambung.db"
WIB = timezone(timedelta(hours=7))
BATCH = 40

ROUTINE_HOUR = {"makan": 18, "mandi": 17, "main": 8}
MISSION_WORDS = ["mau", "lagi", "tidak", "berhenti", "bantu", "selesai", "minum", "makan"]
# Kata yang dipakai anak, urut dari yang paling awal muncul.
CHILD_POOL = ["mau", "lagi", "tidak", "makan", "minum", "selesai", "bantu", "itu", "ya", "aku", "main", "mandi", "susu", "bola", "ibu"]

# Kata unik per pekan (pekan -2, -1, 0) → menghasilkan trend_3w yang dimaksud.
# Catatan sesi tatap muka ilustratif untuk D4: (berapa hari lalu, catatan terapis, fokus pekan depan).
SESSIONS = [
    (23, "Pengenalan SELESAI; orang tua diajari memodelkan sambil bicara. (ilustratif)", "Modeling SELESAI saat makan"),
    (9, "MAU spontan tiga kali saat sesi. BANTU masih perlu jeda tunggu lebih panjang. (ilustratif)", "Jeda tunggu 10 detik"),
]

FAMILIES = [
    {"nickname": "Arka", "age_years": 5, "routine": "makan", "weekly": (4, 5, 9), "mission_rate": 0.85},  # naik
    {"nickname": "Nadia", "age_years": 4, "routine": "mandi", "weekly": (4, 5, 5), "mission_rate": 0.7},
    {"nickname": "Bima", "age_years": 6, "routine": "main", "weekly": (7, 7, 3), "mission_rate": 0.5},  # turun
    {"nickname": "Tiara", "age_years": 3, "routine": "makan", "weekly": (0, 2, 3), "mission_rate": 0.05},  # misi jarang
    {"nickname": "Reza", "age_years": 7, "routine": "mandi", "weekly": (5, 5, 5), "mission_rate": 0.9},  # tetap
]


# ---------------------------------------------------------------- HTTP


def http(method: str, url: str, token: str | None = None, body: dict | None = None, timeout: float = 10) -> tuple[int, object]:
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            raw = r.read()
            return r.status, (json.loads(raw) if raw else None)
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            return e.code, json.loads(raw)
        except ValueError:
            return e.code, raw.decode(errors="replace")


def check_health(server: str) -> None:
    try:
        status, body = http("GET", f"{server}/v1/health", timeout=3)
    except OSError as e:
        sys.exit(f"Server tidak terjangkau di {server}: {e}")
    if status != 200 or not isinstance(body, dict) or body.get("ok") is not True:
        sys.exit(f"{server} bukan server Nyambung (health: {status} {body})")


def therapist_token(arg: str | None) -> str:
    if arg:
        return arg
    raw = os.environ.get("NYAMBUNG_THERAPIST_TOKENS", "")
    first = raw.split(";")[0]
    if ":" not in first:
        sys.exit("Token terapis tidak ada: pakai --token atau set NYAMBUNG_THERAPIST_TOKENS")
    return first.split(":", 1)[0].strip()


# ---------------------------------------------------------------- perangkat tiruan


class Device:
    """Satu perangkat keluarga: berkas SQLite dengan skema aplikasi + berkas meta (token, child)."""

    def __init__(self, child_id: str):
        SIM_DIR.mkdir(parents=True, exist_ok=True)
        self.child_id = child_id
        self.path = SIM_DIR / f"{child_id}.db"
        self.meta_path = SIM_DIR / f"{child_id}.json"
        self.conn = sqlite3.connect(self.path, isolation_level=None)
        self.conn.row_factory = sqlite3.Row
        self.conn.executescript(SCHEMA_SQL.read_text(encoding="utf-8"))

    @property
    def meta(self) -> dict:
        return json.loads(self.meta_path.read_text(encoding="utf-8")) if self.meta_path.exists() else {}

    def save_meta(self, **kw) -> None:
        m = self.meta
        m.update(kw)
        self.meta_path.write_text(json.dumps(m, indent=2, ensure_ascii=False), encoding="utf-8")

    def append(self, content: str, method: str, actor: str, prompt: str, at: datetime, context: str | None, session: str) -> None:
        """INSERT event + outbox dalam satu transaksi (sama dengan EventDao.append)."""
        eid = str(uuid.uuid4())
        self.conn.execute("BEGIN")
        try:
            self.conn.execute(
                "INSERT INTO utterance_event (event_id, child_id, ts_device, content, method, actor, prompt_level, context, session_id) "
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                (eid, self.child_id, at.astimezone(WIB).isoformat(timespec="seconds"), content, method, actor, prompt, context, session),
            )
            self.conn.execute("INSERT INTO outbox (event_id) VALUES (?)", (eid,))
        except BaseException:
            self.conn.execute("ROLLBACK")
            raise
        self.conn.execute("COMMIT")

    def pending(self, limit: int = BATCH) -> list[dict]:
        rows = self.conn.execute(
            "SELECT e.* FROM outbox o JOIN utterance_event e ON e.event_id = o.event_id ORDER BY o.id LIMIT ?", (limit,)
        ).fetchall()
        return [dict(r) for r in rows]

    def mark_synced(self, ids: list[str], ts: str) -> None:
        q = ",".join("?" * len(ids))
        self.conn.execute("BEGIN")
        self.conn.execute(f"UPDATE utterance_event SET synced_at = ? WHERE event_id IN ({q})", (ts, *ids))
        self.conn.execute(f"DELETE FROM outbox WHERE event_id IN ({q})", ids)
        self.conn.execute("COMMIT")

    def outbox_count(self) -> int:
        return self.conn.execute("SELECT COUNT(*) FROM outbox").fetchone()[0]

    def event_ids(self) -> set[str]:
        return {r[0] for r in self.conn.execute("SELECT event_id FROM utterance_event")}


def sync(dev: Device, server: str, crash_after: int | None = None) -> dict:
    token = dev.meta.get("device_token")
    if not token:
        sys.exit("Perangkat belum tertaut (tidak ada device_token).")
    total = {"accepted": 0, "duplicates": 0, "batches": 0}
    while True:
        batch = dev.pending()
        if not batch:
            return total
        events = [{k: e[k] for k in ("event_id", "ts_device", "content", "method", "actor", "prompt_level", "context", "session_id")} for e in batch]
        status, body = http("POST", f"{server}/v1/sync/events", token, {"child_id": dev.child_id, "events": events})
        if status != 200:
            sys.exit(f"Sinkron gagal {status}: {body}")
        total["accepted"] += body["accepted"]
        total["duplicates"] += body["duplicates"]
        total["batches"] += 1
        if crash_after is not None and total["batches"] >= crash_after:
            print(f"CRASH setelah server menjawab 200 untuk batch {total['batches']}, sebelum outbox dibersihkan", flush=True)
            os._exit(137)
        dev.mark_synced([e["event_id"] for e in batch], datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))


# ---------------------------------------------------------------- data demo


def week_vocab(weekly: tuple[int, int, int], days_ago: int) -> list[str]:
    week = days_ago // 7  # 0 = pekan ini
    n = weekly[2 - week] if week <= 2 else weekly[0]
    return CHILD_POOL[:n]


def at_hour(now: datetime, days_ago: int, hour: int, minute: int, second: int) -> datetime:
    """Jam lokal `hour` pada hari yang jatuh di jendela ke-`days_ago`: (now − (d+1) hari, now − d hari].
    Menjaga peristiwa "pekan ini" tidak bocor ke jendela pekan lain."""
    edge = (now - timedelta(days=days_ago)).astimezone(WIB)
    t = edge.replace(hour=hour, minute=minute, second=second, microsecond=0)
    return t if t <= edge else t - timedelta(days=1)


def generate(dev: Device, fam: dict, days: int, now: datetime, rng: random.Random, accepted_target: tuple[str, str, datetime] | None) -> None:
    """Peristiwa realistis per hari: sesi rutinitas dengan ketukan pendamping mendahului sebagian ketukan anak,
    ketukan anak spontan di jam lain, MIS sebagian besar hari, TGT untuk target yang diterima."""
    routine = fam["routine"]
    for d in range(days - 1, -1, -1):
        vocab = week_vocab(fam["weekly"], d)
        week_index = (days - 1 - d) // 7 + 1
        mission_id = f"misi-w{week_index}"
        target_word = MISSION_WORDS[(week_index - 1) % len(MISSION_WORDS)]
        session = str(uuid.uuid4())
        start = at_hour(now, d, ROUTINE_HOUR[routine], rng.randint(0, 25), rng.randint(0, 59)) - timedelta(minutes=30)
        t = start
        did_mission = rng.random() < fam["mission_rate"]
        if did_mission:
            for _ in range(5):  # contoh pendamping di papan misi
                dev.append(target_word, "SEL", "pendamping", "terpancing", t, mission_id, session)
                t += timedelta(seconds=rng.randint(8, 25))
                if vocab and rng.random() < 0.5:  # anak menjawab dalam 60 detik → terpancing
                    dev.append(rng.choice(vocab), "SEL", "anak", "terpancing", t, mission_id, session)
                    t += timedelta(seconds=rng.randint(10, 30))
            dev.append("selesai", "MIS", "pendamping", "terpancing", t + timedelta(minutes=2), mission_id, session)
        elif rng.random() < 0.5:
            dev.append("belum_sempat", "MIS", "pendamping", "terpancing", t + timedelta(minutes=2), mission_id, session)
        # Ketukan anak spontan di luar sesi, semua kata pekan ini muncul setidaknya sekali per pekan.
        if vocab:
            spont_session = str(uuid.uuid4())
            hour = rng.choice([7, 10, 12, 15, 19, 20])
            ts = at_hour(now, d, hour, rng.randint(0, 50), rng.randint(0, 59)) - timedelta(minutes=10)
            picks = vocab if d % 7 == 0 else rng.sample(vocab, k=min(len(vocab), rng.randint(1, 3)))
            for w in picks:
                page_method = "SEL" if w in {"mau", "lagi", "tidak", "makan", "minum", "selesai", "bantu", "itu", "ya", "aku"} else "KAT"
                dev.append(w, page_method, "anak", "spontan", ts, routine, spont_session)
                ts += timedelta(seconds=rng.randint(5, 40))
            if rng.random() < 0.4:
                dev.append(" ".join(picks[:3]), "UCP", "anak", "spontan", ts, routine, spont_session)
    if accepted_target:
        target_id, word, answered = accepted_target
        s = str(uuid.uuid4())
        dev.append("diterima", "TGT", "pendamping", "terpancing", answered, target_id, s)
        for k in range(3):
            at = answered + timedelta(hours=6 + 20 * k)
            if at < now:
                dev.append(word, "SEL", "pendamping", "terpancing", at, routine, s)
                dev.append(word, "SEL", "anak", "terpancing", at + timedelta(seconds=20), routine, s)


def cmd_demo(args: argparse.Namespace) -> None:
    server = args.server.rstrip("/")
    check_health(server)
    if args.email:
        status, sess = http("POST", f"{server}/v1/auth/login", body={"email": args.email, "password": args.password or ""})
        if status != 200:
            sys.exit(f"Login {args.email} gagal {status}: {sess}")
        tok = sess["token"]
    else:
        tok = therapist_token(args.token)
    seed_out = Path(args.out) if args.out else SEED_OUT
    rng = random.Random(args.seed)
    now = datetime.now(timezone.utc)
    out = {"illustrative": True, "generated_at": now.strftime("%Y-%m-%dT%H:%M:%SZ"), "children": [], "events": [], "targets": [], "sessions": []}
    for i, fam in enumerate(FAMILIES):
        status, inv = http("POST", f"{server}/v1/link/invite", tok)
        if status != 201:
            sys.exit(f"Undangan gagal {status}: {inv}")
        child_id = str(uuid.UUID(int=rng.getrandbits(128), version=4))
        status, red = http(
            "POST",
            f"{server}/v1/link/redeem",
            body={"invite_code": inv["invite_code"], "child_id": child_id, "nickname": fam["nickname"], "age_years": fam["age_years"], "routine": fam["routine"]},
        )
        if status != 201:
            sys.exit(f"Tebus gagal {status}: {red}")
        dev = Device(child_id)
        dev.save_meta(nickname=fam["nickname"], device_token=red["device_token"], link_id=red["link_id"], linked_at=red["linked_at"])
        accepted = None
        if i == 1:  # satu target diterima (Nadia)
            body = {"words": ["tunggu"], "note": "Contohkan TUNGGU saat menunggu air mandi hangat. (ilustratif)", "week_index": 2, "routine": fam["routine"]}
            status, tgt = http("POST", f"{server}/v1/children/{child_id}/targets", tok, body)
            if status != 201:
                sys.exit(f"Target gagal {status}: {tgt}")
            accepted = (tgt["target_id"], "tunggu", now - timedelta(days=4))
            out["targets"].append({k: tgt[k] for k in ("target_id", "child_id", "words", "note", "week_index", "routine", "therapist", "created_at")})
        if i == 2:  # satu usulan masih menunggu (Bima)
            body = {"words": ["berhenti"], "note": "Coba BERHENTI saat main bola selesai. (ilustratif)", "week_index": 3, "routine": fam["routine"]}
            status, tgt = http("POST", f"{server}/v1/children/{child_id}/targets", tok, body)
            if status == 201:
                out["targets"].append({k: tgt[k] for k in ("target_id", "child_id", "words", "note", "week_index", "routine", "therapist", "created_at")})
        if i == 0:  # dua catatan sesi tatap muka (Arka), yang terbaru dikirim ke keluarga
            for k, (ago, note, focus) in enumerate(SESSIONS):
                day = (now.astimezone(WIB) - timedelta(days=ago)).date()
                nxt = datetime.combine(day + timedelta(days=14), datetime.min.time()).strftime("%Y-%m-%dT15:30")
                body = {"session_date": day.isoformat(), "note": note, "focus": focus, "next_session": nxt}
                status, sess = http("POST", f"{server}/v1/children/{child_id}/sessions", tok, body)
                if status != 201:
                    sys.exit(f"Catatan sesi gagal {status}: {sess}")
                if k == len(SESSIONS) - 1:
                    share = {"family_text": f"Fokus pekan depan: {focus.lower()}. Ibu sudah memodelkan dengan tempo yang baik. (ilustratif)"}
                    status, sess = http("POST", f"{server}/v1/children/{child_id}/sessions/{sess['note_id']}/share", tok, share)
                out["sessions"].append(sess)
        generate(dev, fam, args.days, now, rng, accepted)
        res = sync(dev, server)
        print(f"{fam['nickname']:<6} child_id={child_id} terkirim={res['accepted']} duplikat={res['duplicates']}")
        rows = dev.conn.execute("SELECT * FROM utterance_event ORDER BY ts_device").fetchall()
        synced = [r["synced_at"] for r in rows if r["synced_at"]]
        out["children"].append(
            {
                "child_id": child_id,
                "nickname": fam["nickname"],
                "age_years": fam["age_years"],
                "routine": fam["routine"],
                "linked_at": red["linked_at"],
                "last_sync": max(synced) if synced else None,
            }
        )
        for r in rows:
            out["events"].append({k: r[k] for k in ("child_id", "event_id", "ts_device", "content", "method", "actor", "prompt_level", "context", "session_id")})
    seed_out.parent.mkdir(parents=True, exist_ok=True)
    seed_out.write_text(json.dumps(out, ensure_ascii=False, indent=1), encoding="utf-8")
    print(
        f"Tulis {seed_out}: {len(out['children'])} anak, {len(out['events'])} peristiwa, {len(out['targets'])} target, "
        f"{len(out['sessions'])} catatan sesi (ilustratif)"
    )


def cmd_tap(args: argparse.Namespace) -> None:
    dev = Device(args.child)
    s = str(uuid.uuid4())
    now = datetime.now(WIB)
    for i in range(args.n):
        dev.append(CHILD_POOL[i % len(CHILD_POOL)], "SEL", "anak", "spontan", now - timedelta(seconds=args.n - i), "makan", s)
    print(f"+{args.n} ketukan; outbox {dev.outbox_count()}")


def cmd_sync(args: argparse.Namespace) -> None:
    server = args.server.rstrip("/")
    check_health(server)
    dev = Device(args.child)
    res = sync(dev, server, args.crash_after)
    print(json.dumps({**res, "outbox": dev.outbox_count()}))


def cmd_verify(args: argparse.Namespace) -> None:
    dev = Device(args.child)
    local = dev.event_ids()
    srv = sqlite3.connect(f"file:{args.server_db}?mode=ro", uri=True)
    remote = {r[0] for r in srv.execute("SELECT event_id FROM event WHERE child_id = ?", (args.child,))}
    print(
        json.dumps(
            {
                "child_id": args.child,
                "local": len(local),
                "server": len(remote),
                "outbox": dev.outbox_count(),
                "missing_on_server": len(local - remote),
                "unknown_on_server": len(remote - local),
                "identical": local == remote,
            }
        )
    )


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--server", default=DEFAULT_SERVER)
    sub = p.add_subparsers(dest="cmd", required=True)
    d = sub.add_parser("demo")
    d.add_argument("--days", type=int, default=21)
    d.add_argument("--token")
    d.add_argument("--email")
    d.add_argument("--password")
    d.add_argument("--out")
    d.add_argument("--seed", type=int, default=2026)
    s = sub.add_parser("sync")
    s.add_argument("--child", required=True)
    s.add_argument("--crash-after", type=int)
    v = sub.add_parser("verify")
    v.add_argument("--child", required=True)
    v.add_argument("--server-db", default=os.environ.get("NYAMBUNG_DB_PATH", str(DEFAULT_SERVER_DB)))
    t = sub.add_parser("tap")
    t.add_argument("--child", required=True)
    t.add_argument("--n", type=int, default=10)
    args = p.parse_args()
    {"demo": cmd_demo, "sync": cmd_sync, "verify": cmd_verify, "tap": cmd_tap}[args.cmd](args)


if __name__ == "__main__":
    main()
