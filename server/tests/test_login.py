from datetime import timedelta

from app import auth
from app.db import now_utc, utc_iso
from conftest import TOK_A, bearer, link_child

EMAIL = "rina@klinik.contoh"
PASSWORD = "sandi-rahasia-123"


def make_account(app, email=EMAIL, name="Bu Rina (ilustratif)", password=PASSWORD):
    auth.create_therapist_login(app.state.conn, email, name, password)


def login(client, email=EMAIL, password=PASSWORD):
    return client.post("/v1/auth/login", json={"email": email, "password": password})


def test_password_hash_roundtrip():
    h = auth.hash_password("sandi-rahasia-123")
    assert h.startswith("scrypt$") and "sandi" not in h
    assert auth.verify_password("sandi-rahasia-123", h)
    assert not auth.verify_password("sandi-salah-123", h)
    assert auth.hash_password("sandi-rahasia-123") != h  # garam acak


def test_login_returns_session_token(app, client):
    make_account(app)
    r = login(client)
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["therapist"] == "Bu Rina (ilustratif)"
    assert len(body["token"]) >= 32 and body["expires_at"].endswith("Z")
    # server hanya menyimpan hash sesi
    stored = app.state.conn.execute("SELECT token_hash FROM therapist_session").fetchone()["token_hash"]
    assert stored == auth.sha256(body["token"])
    me = client.get("/v1/auth/me", headers=bearer(body["token"]))
    assert me.status_code == 200 and me.json() == {"therapist": "Bu Rina (ilustratif)", "email": EMAIL}


def test_email_is_case_insensitive(app, client):
    make_account(app)
    assert login(client, email="  RINA@Klinik.Contoh ").status_code == 200


def test_wrong_password_and_unknown_email_same_401(app, client):
    make_account(app)
    a = login(client, password="salah-salah-salah")
    b = login(client, email="tidak@ada.contoh")
    assert a.status_code == b.status_code == 401
    assert a.json() == b.json()


def test_login_rejects_unknown_fields(client):
    assert client.post("/v1/auth/login", json={"email": EMAIL, "password": PASSWORD, "role": "admin"}).status_code == 422


def test_session_sees_same_children_as_env_token(app, client):
    make_account(app)
    child_id, _, _ = link_child(client, TOK_A)
    token = login(client).json()["token"]
    kids = client.get("/v1/children", headers=bearer(token)).json()["children"]
    assert [k["child_id"] for k in kids] == [child_id]
    assert client.post("/v1/link/invite", headers=bearer(token)).status_code == 201


def test_session_cannot_sync_as_device(app, client):
    make_account(app)
    token = login(client).json()["token"]
    assert client.post("/v1/sync/events", headers=bearer(token), json={"child_id": "x", "events": []}).status_code == 403


def test_logout_revokes_session(app, client):
    make_account(app)
    token = login(client).json()["token"]
    assert client.post("/v1/auth/logout", headers=bearer(token)).status_code == 204
    assert client.get("/v1/children", headers=bearer(token)).status_code == 401


def test_expired_session_401(app, client):
    make_account(app)
    token = login(client).json()["token"]
    past = utc_iso(now_utc() - timedelta(minutes=1))
    app.state.conn.execute("UPDATE therapist_session SET expires_at = ?", (past,))
    assert client.get("/v1/children", headers=bearer(token)).status_code == 401


def test_me_for_env_token_has_no_email(client):
    r = client.get("/v1/auth/me", headers=bearer(TOK_A))
    assert r.status_code == 200 and r.json() == {"therapist": "Bu Rina (ilustratif)", "email": None}


def test_create_login_validates(app):
    conn = app.state.conn
    for email, pw in [("bukan-email", PASSWORD), (EMAIL, "pendek")]:
        try:
            auth.create_therapist_login(conn, email, "X", pw)
        except ValueError:
            continue
        raise AssertionError(f"harus ditolak: {email!r}")
    make_account(app)
    try:
        make_account(app)
    except ValueError:
        return
    raise AssertionError("email ganda harus ditolak")
