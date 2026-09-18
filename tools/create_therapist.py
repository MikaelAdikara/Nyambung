"""Buat akun login terapis langsung di DB server (tidak ada pendaftaran terbuka: klinik di-onboard manual).

  python tools/create_therapist.py --email rina@klinik.id --name "Bu Rina"        # kata sandi ditanyakan
  python tools/create_therapist.py --demo                                          # akun demo ILUSTRATIF

DB: --db atau NYAMBUNG_DB_PATH, bawaan server/data/nyambung.db. Jalankan dengan python dari server/.venv.
Akun --demo memakai kata sandi yang tertulis di README, jadi hanya untuk server lokal/demo.
"""

from __future__ import annotations

import argparse
import getpass
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "server"))

from app import auth  # noqa: E402
from app.db import connect, db_path  # noqa: E402

# Nama sama dengan contoh NYAMBUNG_THERAPIST_TOKENS, jadi anak yang ditautkan lewat token env ikut terlihat.
DEMO_ACCOUNTS = [
    ("rina@demo.nyambung.id", "Bu Rina (ilustratif)", "nyambung-demo"),
    ("dimas@demo.nyambung.id", "Pak Dimas (ilustratif)", "nyambung-demo"),
]


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--db", default=str(db_path()))
    p.add_argument("--email")
    p.add_argument("--name")
    p.add_argument("--demo", action="store_true", help="buat akun demo ilustratif (lewati yang sudah ada)")
    args = p.parse_args()

    conn = connect(args.db)
    if args.demo:
        for email, name, password in DEMO_ACCOUNTS:
            try:
                auth.create_therapist_login(conn, email, name, password)
                print(f"dibuat  {email:<26} {name}")
            except ValueError as e:
                print(f"lewati  {email:<26} {e}")
        print(f"Kata sandi akun demo: {DEMO_ACCOUNTS[0][2]}  (ILUSTRATIF, jangan dipakai di server sungguhan)")
        return

    if not args.email or not args.name:
        p.error("--email dan --name wajib (atau pakai --demo)")
    password = getpass.getpass("Kata sandi (min 8 karakter): ")
    if password != getpass.getpass("Ulangi kata sandi: "):
        sys.exit("Kata sandi tidak sama.")
    try:
        auth.create_therapist_login(conn, args.email, args.name, password)
    except ValueError as e:
        sys.exit(f"Gagal: {e}")
    print(f"Akun {auth.normalize_email(args.email)} ({args.name}) dibuat di {args.db}")


if __name__ == "__main__":
    main()
