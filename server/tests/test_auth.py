from datetime import timedelta

from app import auth
from app.db import now_utc, utc_iso
from conftest import TOK_A, TOK_B, bearer, ev, link_child


def test_invite_code_shape(client):
    r = client.post("/v1/link/invite", headers=bearer(TOK_A))
    assert r.status_code == 201
    body = r.json()
    assert body["therapist"] == "Bu Rina (ilustratif)"
    code = body["invite_code"]
    assert len(code) == 8 and all(c in auth.INVITE_ALPHABET for c in code)
    assert not set(code) & set("IO01")


def test_no_token_401(client):
    assert client.post("/v1/link/invite").status_code == 401
    assert client.get("/v1/children").status_code == 401
    assert client.post("/v1/sync/events", json={"child_id": "x", "events": []}).status_code == 401


def test_wrong_token_401(client):
    assert client.get("/v1/children", headers=bearer("salah-salah-salah-salah")).status_code == 401


def test_short_env_token_ignored():
    assert auth.parse_therapist_env("pendek:Bu X;panjang-sekali-123456:Bu Y") == [("panjang-sekali-123456", "Bu Y")]


def test_device_other_child_403(client):
    child_a, tok_a, _ = link_child(client)
    child_b, _, _ = link_child(client, nickname="Nadia")
    r = client.post("/v1/sync/events", headers=bearer(tok_a), json={"child_id": child_b, "events": [ev()]})
    assert r.status_code == 403
    assert client.get(f"/v1/children/{child_b}/targets", headers=bearer(tok_a)).status_code == 403
    assert client.get(f"/v1/children/{child_a}/targets", headers=bearer(tok_a)).status_code == 200


def test_other_therapist_404(client):
    child, _, _ = link_child(client, therapist_token=TOK_A)
    assert client.get(f"/v1/children/{child}/summary", headers=bearer(TOK_B)).status_code == 404
    assert client.get(f"/v1/children/{child}/targets", headers=bearer(TOK_B)).status_code == 404
    assert client.post(f"/v1/children/{child}/targets", headers=bearer(TOK_B), json={"words": ["mau"]}).status_code == 404
    assert client.get("/v1/children", headers=bearer(TOK_B)).json()["active_families"] == 0
    assert client.get(f"/v1/children/{child}/summary", headers=bearer(TOK_A)).status_code == 200


def test_revoke_then_401_and_hidden(client):
    child, tok, link_id = link_child(client)
    assert client.delete(f"/v1/link/{link_id}", headers=bearer(tok)).status_code == 204
    r = client.post("/v1/sync/events", headers=bearer(tok), json={"child_id": child, "events": [ev()]})
    assert r.status_code == 401
    assert client.get(f"/v1/children/{child}/summary", headers=bearer(TOK_A)).status_code == 404
    assert client.get("/v1/children", headers=bearer(TOK_A)).json()["active_families"] == 0


def test_revoke_other_link_403(client):
    _, tok_a, _ = link_child(client)
    _, _, link_b = link_child(client, nickname="Nadia")
    assert client.delete(f"/v1/link/{link_b}", headers=bearer(tok_a)).status_code == 403


def test_invite_used_twice_410(client):
    code = client.post("/v1/link/invite", headers=bearer(TOK_A)).json()["invite_code"]
    body = {"invite_code": code, "child_id": "c1", "nickname": "Arka", "age_years": 5, "routine": "makan"}
    assert client.post("/v1/link/redeem", json=body).status_code == 201
    assert client.post("/v1/link/redeem", json=body).status_code == 410


def test_invite_unknown_404_and_expired_410(client, app):
    body = {"invite_code": "ZZZZZZZZ", "child_id": "c1", "nickname": "Arka", "age_years": 5, "routine": "makan"}
    assert client.post("/v1/link/redeem", json=body).status_code == 404
    old = utc_iso(now_utc() - timedelta(days=8))
    app.state.conn.execute("INSERT INTO invite (invite_code, therapist, created_at) VALUES ('OLDCODE2', 'Bu Rina (ilustratif)', ?)", (old,))
    body["invite_code"] = "OLDCODE2"
    assert client.post("/v1/link/redeem", json=body).status_code == 410


def test_redeem_rejects_unknown_field(client):
    code = client.post("/v1/link/invite", headers=bearer(TOK_A)).json()["invite_code"]
    body = {"invite_code": code, "child_id": "c1", "nickname": "Arka", "routine": "makan", "diagnosis": "x"}
    assert client.post("/v1/link/redeem", json=body).status_code == 422


def test_tokens_stored_hashed(client, app):
    _, tok, _ = link_child(client)
    conn = app.state.conn
    assert conn.execute("SELECT COUNT(*) FROM therapist_link WHERE device_token_hash = ?", (tok,)).fetchone()[0] == 0
    assert conn.execute("SELECT COUNT(*) FROM therapist_account WHERE token_hash = ?", (TOK_A,)).fetchone()[0] == 0
