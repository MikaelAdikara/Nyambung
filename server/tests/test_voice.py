"""Frasa bersuara dan klon suara keluarga. Penyedia suara diganti tiruan: tes tidak pernah memanggil OpenAI/ElevenLabs."""

import base64

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.services.voice import VoiceError, phrase_word_id
from conftest import TOK_A, TOK_B, TOKENS, bearer, ev, link_child, push

MP3 = b"ID3" + b"\x00" * 400


class FakeVoice:
    def __init__(self, openai=True, eleven=True):
        self.keys = {"openai": openai, "elevenlabs": eleven}
        self.cloned: list[tuple[str, list]] = []
        self.deleted: list[str] = []
        self.spoken: list[tuple[str, str]] = []

    def available(self):
        return dict(self.keys)

    def openai_tts(self, text, style):
        if not self.keys["openai"]:
            raise VoiceError("belum aktif", 503)
        self.spoken.append((style, text))
        return MP3

    def clone(self, name, samples):
        if not self.keys["elevenlabs"]:
            raise VoiceError("belum aktif", 503)
        self.cloned.append((name, samples))
        return f"voice-{len(self.cloned)}"

    def clone_tts(self, voice_id, text):
        self.spoken.append((voice_id, text))
        return MP3

    def delete_clone(self, voice_id):
        self.deleted.append(voice_id)


@pytest.fixture()
def fake():
    return FakeVoice()


@pytest.fixture()
def vclient(tmp_path, fake):
    return TestClient(create_app(tmp_path / "test.db", TOKENS, voice=fake))


def sample():
    return {"filename": "contoh-1.m4a", "data_b64": base64.b64encode(b"\x00" * 300).decode()}


def clone_body(**kw):
    return {"consent": True, "consent_by": "Ibu", "samples": [sample()], **kw}


def test_word_id_formula_is_stable():
    assert phrase_word_id("Jangan nyontek!", "3fa9c1d2-0000-4000-8000-000000000000") == "frs-jangan_nyontek-3fa9c1d2"
    assert phrase_word_id("???", "abcdef12-3456") == "frs-frasa-abcdef12"


def test_therapist_phrase_is_a_proposal_until_family_answers(vclient, fake):
    child, dev, _ = link_child(vclient)
    r = vclient.post(f"/v1/children/{child}/phrases", headers=bearer(TOK_A), json={"text": "  Jangan   nyontek ", "voice": "cewe"})
    assert r.status_code == 201, r.text
    p = r.json()
    assert p["text"] == "Jangan nyontek"
    assert p["status"] == "usulan" and p["created_by"] == "Bu Rina (ilustratif)"
    assert fake.spoken == [("cewe", "Jangan nyontek")]

    audio = vclient.get(f"/v1/children/{child}/phrases/{p['phrase_id']}/audio", headers=bearer(dev))
    assert audio.status_code == 200 and audio.content == MP3 and audio.headers["content-type"] == "audio/mpeg"

    push(vclient, child, dev, [ev(content="diterima", method="TGT", actor="pendamping", prompt="terpancing", context=p["phrase_id"])])
    push(vclient, child, dev, [ev(content=p["word_id"], method="PRS", actor="pendamping", prompt="terpancing")])
    rows = vclient.get(f"/v1/children/{child}/phrases", headers=bearer(TOK_A)).json()
    assert rows[0]["status"] == "diterima" and rows[0]["used_count"] == 1


def test_family_phrase_is_accepted_immediately(vclient):
    child, dev, _ = link_child(vclient)
    r = vclient.post(f"/v1/children/{child}/phrases", headers=bearer(dev), json={"text": "Mau main", "voice": "cowo"})
    assert r.status_code == 201
    assert r.json()["status"] == "diterima" and r.json()["created_by"] == "keluarga"


def test_access_is_scoped_to_linked_child(vclient):
    child, dev, _ = link_child(vclient)
    other, other_dev, _ = link_child(vclient, nickname="Bima")
    body = {"text": "Halo", "voice": "cowo"}
    assert vclient.post(f"/v1/children/{child}/phrases", headers=bearer(TOK_B), json=body).status_code == 404
    assert vclient.post(f"/v1/children/{child}/phrases", headers=bearer(other_dev), json=body).status_code == 403
    pid = vclient.post(f"/v1/children/{child}/phrases", headers=bearer(dev), json=body).json()["phrase_id"]
    assert vclient.get(f"/v1/children/{other}/phrases/{pid}/audio", headers=bearer(other_dev)).status_code == 404
    assert vclient.get(f"/v1/children/{child}/phrases", headers=bearer(TOK_B)).status_code == 404


def test_input_validation(vclient):
    child, dev, _ = link_child(vclient)
    url = f"/v1/children/{child}/phrases"
    assert vclient.post(url, headers=bearer(dev), json={"text": "x" * 61, "voice": "cowo"}).status_code == 422
    assert vclient.post(url, headers=bearer(dev), json={"text": "   ", "voice": "cowo"}).status_code == 422
    assert vclient.post(url, headers=bearer(dev), json={"text": "a", "voice": "robot"}).status_code == 422
    assert vclient.post(url, headers=bearer(dev), json={"text": "a", "voice": "cowo", "extra": 1}).status_code == 422


def test_family_voice_requires_active_clone(vclient, fake):
    child, dev, _ = link_child(vclient)
    url = f"/v1/children/{child}/phrases"
    assert vclient.post(url, headers=bearer(TOK_A), json={"text": "Jangan nyontek", "voice": "keluarga"}).status_code == 409

    r = vclient.post(f"/v1/children/{child}/voice/clone", headers=bearer(dev), json=clone_body())
    assert r.status_code == 200, r.text
    assert r.json()["clone_active"] is True and r.json()["clone_consent_by"] == "Ibu"
    name, samples = fake.cloned[0]
    assert "Arka" not in name  # nama anak tidak dikirim ke penyedia
    assert samples[0][1] == b"\x00" * 300

    r = vclient.post(url, headers=bearer(TOK_A), json={"text": "Jangan nyontek", "voice": "keluarga"})
    assert r.status_code == 201 and fake.spoken[-1] == ("voice-1", "Jangan nyontek")

    r = vclient.delete(f"/v1/children/{child}/voice/clone", headers=bearer(dev))
    assert r.json()["clone_active"] is False and fake.deleted == ["voice-1"]
    assert vclient.post(url, headers=bearer(TOK_A), json={"text": "Lagi", "voice": "keluarga"}).status_code == 409


def test_clone_needs_consent_and_device(vclient):
    child, dev, _ = link_child(vclient)
    url = f"/v1/children/{child}/voice/clone"
    assert vclient.post(url, headers=bearer(dev), json=clone_body(consent=False)).status_code == 422
    assert vclient.post(url, headers=bearer(TOK_A), json=clone_body()).status_code == 403
    bad = clone_body(samples=[{"filename": "a.m4a", "data_b64": "!" * 200}])
    assert vclient.post(url, headers=bearer(dev), json=bad).status_code == 422
    bad = clone_body(samples=[{"filename": "../etc.m4a", "data_b64": "A" * 200}])
    assert vclient.post(url, headers=bearer(dev), json=bad).status_code == 422


def test_reclone_deletes_previous_voice(vclient, fake):
    child, dev, _ = link_child(vclient)
    url = f"/v1/children/{child}/voice/clone"
    vclient.post(url, headers=bearer(dev), json=clone_body())
    vclient.post(url, headers=bearer(dev), json=clone_body(consent_by="Ayah"))
    assert fake.deleted == ["voice-1"]
    status = vclient.get(f"/v1/children/{child}/voice", headers=bearer(TOK_A)).json()
    assert status["clone_consent_by"] == "Ayah"


def test_missing_provider_key_reports_503(tmp_path):
    client = TestClient(create_app(tmp_path / "t.db", TOKENS, voice=FakeVoice(openai=False, eleven=False)))
    child, dev, _ = link_child(client)
    status = client.get(f"/v1/children/{child}/voice", headers=bearer(dev)).json()
    assert status["openai"] is False and status["elevenlabs"] is False
    assert client.post(f"/v1/children/{child}/phrases", headers=bearer(dev), json={"text": "Halo", "voice": "cowo"}).status_code == 503
    assert client.post(f"/v1/children/{child}/voice/clone", headers=bearer(dev), json=clone_body()).status_code == 503
    assert client.get(f"/v1/children/{child}/phrases", headers=bearer(dev)).json() == []
