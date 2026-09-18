"""Catatan sesi (D4), ringkasan untuk keluarga, dan waktu tinjauan (D1)."""

from conftest import TOK_A, TOK_B, bearer, link_child, push, ev


def _note(**over):
    body = {"session_date": "2026-09-09", "note": "MAU spontan tiga kali saat sesi.", "focus": "Jeda tunggu 10 detik", "next_session": "2026-09-23T15:30"}
    body.update(over)
    return body


def test_session_note_lifecycle_and_privacy(client):
    child_id, device, _ = link_child(client)
    r = client.post(f"/v1/children/{child_id}/sessions", headers=bearer(TOK_A), json=_note())
    assert r.status_code == 201, r.text
    note = r.json()
    assert note["note"].startswith("MAU") and note["shared_at"] is None

    # Belum dikirim: keluarga tidak menerima apa pun.
    shared = client.get(f"/v1/children/{child_id}/shared-summaries", headers=bearer(device))
    assert shared.status_code == 200 and shared.json() == []

    r = client.put(f"/v1/children/{child_id}/sessions/{note['note_id']}", headers=bearer(TOK_A), json=_note(focus="Jeda 8 detik"))
    assert r.status_code == 200 and r.json()["focus"] == "Jeda 8 detik"

    r = client.post(
        f"/v1/children/{child_id}/sessions/{note['note_id']}/share",
        headers=bearer(TOK_A),
        json={"family_text": "Fokus pekan depan: jeda tunggu sebelum membantu."},
    )
    assert r.status_code == 200 and r.json()["shared_at"]

    rows = client.get(f"/v1/children/{child_id}/shared-summaries", headers=bearer(device)).json()
    assert len(rows) == 1
    assert rows[0]["family_text"].startswith("Fokus pekan depan")
    # Catatan sesi milik terapis tidak pernah ikut ke perangkat.
    assert "note" not in rows[0]
    assert "MAU spontan" not in str(rows[0])

    listed = client.get(f"/v1/children/{child_id}/sessions", headers=bearer(TOK_A)).json()
    assert [n["note_id"] for n in listed] == [note["note_id"]]


def test_session_notes_scoped_to_therapist(client):
    child_id, device, _ = link_child(client)
    note = client.post(f"/v1/children/{child_id}/sessions", headers=bearer(TOK_A), json=_note()).json()
    # Terapis lain tidak tertaut ke anak ini: 404, tidak membocorkan keberadaan.
    assert client.get(f"/v1/children/{child_id}/sessions", headers=bearer(TOK_B)).status_code == 404
    # Perangkat tidak bisa membaca catatan sesi.
    assert client.get(f"/v1/children/{child_id}/sessions", headers=bearer(device)).status_code == 403
    r = client.put(f"/v1/children/{child_id}/sessions/{note['note_id']}", headers=bearer(TOK_B), json=_note())
    assert r.status_code == 404


def test_session_validation(client):
    child_id, _, _ = link_child(client)
    url = f"/v1/children/{child_id}/sessions"
    assert client.post(url, headers=bearer(TOK_A), json=_note(session_date="9 Sep")).status_code == 422
    assert client.post(url, headers=bearer(TOK_A), json=_note(note="")).status_code == 422
    assert client.post(url, headers=bearer(TOK_A), json={**_note(), "diagnosis": "x"}).status_code == 422


def test_shared_summaries_hidden_after_revoke(client):
    child_id, device, link_id = link_child(client)
    note = client.post(f"/v1/children/{child_id}/sessions", headers=bearer(TOK_A), json=_note()).json()
    client.post(f"/v1/children/{child_id}/sessions/{note['note_id']}/share", headers=bearer(TOK_A), json={"family_text": "Halo"})
    assert client.delete(f"/v1/link/{link_id}", headers=bearer(device)).status_code == 204
    # Setelah dicabut, token perangkat tidak berlaku lagi.
    assert client.get(f"/v1/children/{child_id}/shared-summaries", headers=bearer(device)).status_code == 401


def test_review_time_average(client):
    child_id, device, _ = link_child(client)
    push(client, child_id, device, [ev()])
    assert client.get("/v1/children", headers=bearer(TOK_A)).json()["review_avg_minutes"] is None
    for secs in (240, 312):
        r = client.post("/v1/review-time", headers=bearer(TOK_A), json={"child_id": child_id, "seconds": secs})
        assert r.status_code == 204
    body = client.get("/v1/children", headers=bearer(TOK_A)).json()
    assert body["review_avg_minutes"] == 4.6
    assert body["review_count_30d"] == 2
    # Terapis lain tidak ikut terhitung dan tidak boleh mencatat untuk anak yang bukan binaannya.
    assert client.post("/v1/review-time", headers=bearer(TOK_B), json={"child_id": child_id, "seconds": 60}).status_code == 404
    assert client.post("/v1/review-time", headers=bearer(TOK_A), json={"child_id": child_id, "seconds": 1}).status_code == 422
