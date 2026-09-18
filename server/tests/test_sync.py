import sqlite3

import pytest

from conftest import bearer, ev, link_child, push


def test_health(client):
    r = client.get("/v1/health")
    assert r.status_code == 200
    body = r.json()
    assert body["ok"] is True and body["events"] == 0 and body["time"].endswith("Z")


def test_sync_idempotent(client):
    child, tok, _ = link_child(client)
    batch = [ev() for _ in range(40)]
    assert push(client, child, tok, batch) == {"accepted": 40, "duplicates": 0, "rejected": []}
    assert push(client, child, tok, batch) == {"accepted": 0, "duplicates": 40, "rejected": []}
    assert client.get("/v1/health").json()["events"] == 40


def test_partial_duplicate_counts(client):
    child, tok, _ = link_child(client)
    first = [ev() for _ in range(3)]
    push(client, child, tok, first)
    assert push(client, child, tok, first[:1] + [ev()]) == {"accepted": 1, "duplicates": 1, "rejected": []}


def test_unknown_field_rejected(client):
    child, tok, _ = link_child(client)
    r = client.post("/v1/sync/events", headers=bearer(tok), json={"child_id": child, "events": [ev()], "unique_words": 9})
    assert r.status_code == 422
    e = ev()
    e["unique_words"] = 9
    r = client.post("/v1/sync/events", headers=bearer(tok), json={"child_id": child, "events": [e]})
    assert r.status_code == 422


def test_ts_without_timezone_rejected(client):
    child, tok, _ = link_child(client)
    e = ev()
    e["ts_device"] = "2026-09-18T10:15:00"
    r = client.post("/v1/sync/events", headers=bearer(tok), json={"child_id": child, "events": [e]})
    assert r.status_code == 422


def test_z_suffix_accepted_and_local_fields(client, app):
    child, tok, _ = link_child(client)
    e = ev()
    e["ts_device"] = "2026-09-18T10:15:00+07:00"
    push(client, child, tok, [e])
    row = app.state.conn.execute("SELECT ts_utc, hour_local, date_local FROM event").fetchone()
    assert (row["ts_utc"], row["hour_local"], row["date_local"]) == ("2026-09-18T03:15:00Z", 10, "2026-09-18")
    z = ev()
    z["ts_device"] = "2026-09-18T03:15:00Z"
    assert push(client, child, tok, [z])["accepted"] == 1


def test_bad_method_rejected(client):
    child, tok, _ = link_child(client)
    r = client.post("/v1/sync/events", headers=bearer(tok), json={"child_id": child, "events": [ev(method="XYZ")]})
    assert r.status_code == 422


def test_event_table_append_only(client, app):
    child, tok, _ = link_child(client)
    push(client, child, tok, [ev()])
    conn = app.state.conn
    with pytest.raises(sqlite3.IntegrityError):
        conn.execute("UPDATE event SET content = 'x'")
    with pytest.raises(sqlite3.IntegrityError):
        conn.execute("DELETE FROM event")


def test_sync_log_written(client, app):
    child, tok, _ = link_child(client)
    push(client, child, tok, [ev(), ev()])
    row = app.state.conn.execute("SELECT accepted, duplicates FROM sync_log WHERE child_id = ?", (child,)).fetchone()
    assert (row["accepted"], row["duplicates"]) == (2, 0)
