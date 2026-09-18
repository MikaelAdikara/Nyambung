import os
import sys
import tempfile
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path

import pytest

# Modul app.main membuat `app` saat diimpor; arahkan DB bawaannya ke berkas sementara.
os.environ["NYAMBUNG_DB_PATH"] = str(Path(tempfile.mkdtemp()) / "import.db")
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from fastapi.testclient import TestClient  # noqa: E402

from app.main import create_app  # noqa: E402

TOK_A = "tokA-rina-0123456789"
TOK_B = "tokB-dimas-0123456789"
TOKENS = f"{TOK_A}:Bu Rina (ilustratif);{TOK_B}:Pak Dimas (ilustratif)"
WIB = timezone(timedelta(hours=7))


def bearer(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def app(tmp_path):
    return create_app(tmp_path / "test.db", TOKENS)


@pytest.fixture()
def client(app):
    return TestClient(app)


def link_child(client, therapist_token=TOK_A, nickname="Arka", child_id=None, routine="makan"):
    """Undangan terapis → tebus oleh perangkat. Mengembalikan (child_id, device_token, link_id)."""
    code = client.post("/v1/link/invite", headers=bearer(therapist_token)).json()["invite_code"]
    child_id = child_id or str(uuid.uuid4())
    r = client.post(
        "/v1/link/redeem",
        json={"invite_code": code, "child_id": child_id, "nickname": nickname, "age_years": 5, "routine": routine},
    )
    assert r.status_code == 201, r.text
    body = r.json()
    return child_id, body["device_token"], body["link_id"]


def ev(content="mau", method="SEL", actor="anak", prompt="spontan", at=None, context="makan", event_id=None):
    at = at or datetime.now(WIB)
    return {
        "event_id": event_id or str(uuid.uuid4()),
        "ts_device": at.astimezone(WIB).isoformat(timespec="seconds"),
        "content": content,
        "method": method,
        "actor": actor,
        "prompt_level": prompt,
        "context": context,
        "session_id": "s-1",
    }


def push(client, child_id, token, events):
    r = client.post("/v1/sync/events", headers=bearer(token), json={"child_id": child_id, "events": events})
    assert r.status_code == 200, r.text
    return r.json()
