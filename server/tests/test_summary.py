"""Agregasi kontrak §5. Semua waktu relatif terhadap `now`, supaya tes tidak bergantung jam dinding."""

from datetime import datetime, timedelta

from app.services import summary as agg
from conftest import TOK_A, WIB, bearer, ev, link_child, push

WORDS = ["mau", "tidak", "lagi", "selesai", "bantu", "minum", "makan", "itu", "ya", "aku"]


def taps_for_week(week_ago: int, n_words: int, now: datetime) -> list[dict]:
    """Ketukan anak dengan `n_words` kata berbeda di pekan ke-`week_ago` (0 = 7 hari terakhir)."""
    base = now - timedelta(days=7 * week_ago + 2)
    return [ev(content=WORDS[i], at=base - timedelta(minutes=i)) for i in range(n_words)]


def test_trend_3w_four_children(client, app):
    now = datetime.now(WIB)
    cases = {"naik": (3, 3, 6), "tetap": (4, 4, 4), "turun": (6, 6, 2), "baru": (0, 0, 5)}
    ids = {}
    for label, (w2, w1, w0) in cases.items():
        child, tok, _ = link_child(client, nickname=label)
        events = taps_for_week(2, w2, now) + taps_for_week(1, w1, now) + taps_for_week(0, w0, now)
        push(client, child, tok, events)
        ids[label] = child
    for label, child in ids.items():
        assert agg.summary(app.state.conn, child, 7)["trend_3w"] == label, label


def test_trend_ignores_empty_previous_week(client, app):
    now = datetime.now(WIB)
    child, tok, _ = link_child(client)
    push(client, child, tok, taps_for_week(1, 4, now) + taps_for_week(0, 4, now))  # pekan 2 kosong
    assert agg.summary(app.state.conn, child, 7)["trend_3w"] == "tetap"


def test_core_fields(client, app):
    now = datetime.now(WIB)
    child, tok, _ = link_child(client)
    h = lambda hours: now - timedelta(hours=hours)  # noqa: E731
    events = [
        ev("mau", actor="pendamping", prompt="terpancing", at=h(1)),
        ev("mau", actor="anak", prompt="terpancing", at=h(1)),
        ev("mau", actor="anak", prompt="spontan", at=h(2)),
        ev("tidak", method="KAT", actor="anak", prompt="spontan", at=h(3)),
        ev("berhenti", method="PRS", actor="anak", prompt="spontan", at=h(4)),
        ev("mau", method="HAP", at=h(5)),  # bukan ketukan
        ev("mau tidak", method="UCP", at=h(5)),  # bukan ketukan
        ev("selesai", method="MIS", actor="pendamping", prompt="terpancing", at=h(6), context="misi-w1"),
        ev("selesai", method="MIS", actor="pendamping", prompt="terpancing", at=h(6) - timedelta(minutes=1), context="misi-w1"),
        ev("belum_sempat", method="MIS", actor="pendamping", prompt="terpancing", at=h(30), context="misi-w1"),
        ev("lagi", actor="anak", at=now - timedelta(days=9)),  # jendela sebelumnya
    ]
    push(client, child, tok, events)
    s = agg.summary(app.state.conn, child, 7)
    assert s["unique_words"] == 3
    assert s["unique_words_prev"] == 1
    assert s["child_taps"] == 4 and s["parent_taps"] == 1 and s["total_taps"] == 5
    assert s["spontaneous_taps"] == 3 and s["prompted_taps"] == 1
    assert s["spontaneous_ratio"] == 0.75
    assert s["top_words"][0] == {"word": "mau", "count": 2}
    assert s["word_counts"] == {"mau": 2, "berhenti": 1, "tidak": 1}
    assert s["missions_done"] == len({h(6).date(), (h(6) - timedelta(minutes=1)).date()})
    assert s["missions_skipped"] == 1
    assert s["missions_total"] == 7
    expected = [0] * 24
    for hours in (1, 2, 3, 4):
        expected[h(hours).hour] += 1
    assert s["hour_histogram"] == expected
    assert len(s["weekly_unique_6w"]) == 6 and s["weekly_unique_6w"][-1] == 3 and s["weekly_unique_6w"][-2] == 1
    assert s["last_sync"] is not None and s["linked_weeks"] == 0 and s["pending_targets"] == 0


def test_spontaneous_ratio_null_without_child_taps(client, app):
    child, tok, _ = link_child(client)
    push(client, child, tok, [ev(actor="pendamping", prompt="terpancing")])
    assert agg.summary(app.state.conn, child, 7)["spontaneous_ratio"] is None


def test_summary_endpoint_days_bounds(client):
    child, _, _ = link_child(client)
    assert client.get(f"/v1/children/{child}/summary?days=0", headers=bearer(TOK_A)).status_code == 422
    assert client.get(f"/v1/children/{child}/summary?days=91", headers=bearer(TOK_A)).status_code == 422
    r = client.get(f"/v1/children/{child}/summary?days=14", headers=bearer(TOK_A))
    assert r.status_code == 200 and r.json()["days"] == 14 and r.json()["nickname"] == "Arka"


def test_target_lifecycle(client):
    child, tok, _ = link_child(client)
    r = client.post(
        f"/v1/children/{child}/targets",
        headers=bearer(TOK_A),
        json={"words": ["berhenti"], "note": "Contohkan saat makan selesai.", "week_index": 3, "routine": "makan"},
    )
    assert r.status_code == 201
    t = r.json()
    assert t["status"] == "usulan" and t["therapist"] == "Bu Rina (ilustratif)" and t["used_count_since_accept"] == 0
    assert client.get("/v1/children", headers=bearer(TOK_A)).json()["pending_targets"] == 1

    now = datetime.now(WIB)
    push(
        client,
        child,
        tok,
        [
            ev("berhenti", actor="anak", at=now - timedelta(hours=3)),  # sebelum diterima: tidak dihitung
            ev("diterima", method="TGT", actor="pendamping", prompt="terpancing", context=t["target_id"], at=now - timedelta(hours=2)),
            ev("berhenti", actor="pendamping", prompt="terpancing", at=now - timedelta(hours=1)),
            ev("berhenti", method="KAT", actor="anak", at=now - timedelta(minutes=30)),
        ],
    )
    got = client.get(f"/v1/children/{child}/targets", headers=bearer(tok)).json()
    assert got[0]["status"] == "diterima" and got[0]["answered_at"] and got[0]["used_count_since_accept"] == 2
    assert client.get("/v1/children", headers=bearer(TOK_A)).json()["pending_targets"] == 0


def test_target_rejected_and_validation(client):
    child, tok, _ = link_child(client)
    assert client.post(f"/v1/children/{child}/targets", headers=bearer(TOK_A), json={"words": []}).status_code == 422
    assert client.post(f"/v1/children/{child}/targets", headers=bearer(TOK_A), json={"words": list("abcdef")}).status_code == 422
    assert client.post(f"/v1/children/{child}/targets", headers=bearer(TOK_A), json={"words": ["a"], "note": "x" * 601}).status_code == 422
    assert (
        client.post(f"/v1/children/{child}/targets", headers=bearer(TOK_A), json={"words": ["a"], "therapist": "palsu"}).status_code == 422
    )
    t = client.post(f"/v1/children/{child}/targets", headers=bearer(TOK_A), json={"words": ["mau"]}).json()
    push(client, child, tok, [ev("ditolak", method="TGT", actor="pendamping", prompt="terpancing", context=t["target_id"])])
    got = client.get(f"/v1/children/{child}/targets", headers=bearer(TOK_A)).json()
    assert got[0]["status"] == "ditolak" and got[0]["used_count_since_accept"] == 0


def test_children_overview_needs_review(client):
    now = datetime.now(WIB)
    active, tok, _ = link_child(client, nickname="Aktif")
    link_child(client, nickname="Belum sinkron")
    days = [now - timedelta(days=d, hours=1) for d in range(3)]
    push(
        client,
        active,
        tok,
        [ev("mau", at=d) for d in days]
        + [ev("selesai", method="MIS", actor="pendamping", prompt="terpancing", context="misi-w1", at=d) for d in days],
    )
    body = client.get("/v1/children", headers=bearer(TOK_A)).json()
    assert body["active_families"] == 2 and body["unsynced_over_7d"] == 1 and body["needs_review"] == 1
    by_name = {c["nickname"]: c for c in body["children"]}
    assert by_name["Aktif"]["needs_review"] is False and by_name["Aktif"]["missions_done"] == 3
    assert by_name["Belum sinkron"]["needs_review"] is True and by_name["Belum sinkron"]["last_sync"] is None
    assert body["children"][0]["nickname"] == "Belum sinkron"  # yang perlu ditinjau di atas
