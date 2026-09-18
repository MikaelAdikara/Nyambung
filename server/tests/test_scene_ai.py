"""AI pembuat draf visual-scene: auth, validasi, pemetaan koordinat, dan quota."""

import base64
import io

from fastapi.testclient import TestClient
from PIL import Image

from app.main import create_app
from conftest import TOKENS, bearer, link_child


_jpeg = io.BytesIO()
Image.new("RGB", (1, 1), "white").save(_jpeg, format="JPEG")
JPEG = _jpeg.getvalue()


class FakeSceneVision:
    def __init__(self):
        self.calls = 0

    def available(self):
        return True

    def analyze(self, image, allowed_symbols):
        self.calls += 1
        assert image.startswith(b"\xff\xd8")
        assert allowed_symbols == [{"pos": "benda", "category": "tempat", "word_id": "mobil", "label": "MOBIL"}]
        return {
            "model": "fake-vision",
            "candidates": [
                {
                    "observed_label": "mobil mainan",
                    "word_id": "mobil",
                    "box_1000": [200, 100, 450, 400],
                }
            ],
        }


def body(**overrides):
    data = {
        "consent": True,
        "image_mime": "image/jpeg",
        "image_base64": base64.b64encode(JPEG).decode(),
        "allowed_symbols": [{"word_id": "mobil", "label": "MOBIL"}],
    }
    data.update(overrides)
    return data


def test_scene_ai_requires_device_for_same_child(tmp_path):
    fake = FakeSceneVision()
    client = TestClient(create_app(tmp_path / "test.db", TOKENS, scene_vision=fake))
    child_a, token_a, _ = link_child(client)
    child_b, _, _ = link_child(client)

    assert client.get(f"/v1/children/{child_a}/scene-ai/status").status_code == 401
    assert client.post(f"/v1/children/{child_b}/scene-ai/analyze", headers=bearer(token_a), json=body()).status_code == 403
    assert fake.calls == 0


def test_scene_ai_checks_auth_before_large_body_and_caps_stream(tmp_path):
    fake = FakeSceneVision()
    client = TestClient(create_app(tmp_path / "test.db", TOKENS, scene_vision=fake))
    child_id, token, _ = link_child(client)
    url = f"/v1/children/{child_id}/scene-ai/analyze"
    oversized = b"{" + (b"x" * (4 * 1024 * 1024)) + b"}"

    assert client.post(url, content=oversized, headers={"content-type": "application/json"}).status_code == 401
    assert client.post(url, content=oversized, headers={**bearer(token), "content-type": "application/json"}).status_code == 413
    assert fake.calls == 0


def test_scene_ai_returns_normalized_editable_candidates(tmp_path):
    fake = FakeSceneVision()
    client = TestClient(create_app(tmp_path / "test.db", TOKENS, scene_vision=fake))
    child_id, token, _ = link_child(client)

    status = client.get(f"/v1/children/{child_id}/scene-ai/status", headers=bearer(token))
    assert status.status_code == 200
    assert status.json() == {"available": True, "provider": "google", "max_hotspots": 6}

    response = client.post(f"/v1/children/{child_id}/scene-ai/analyze", headers=bearer(token), json=body())
    assert response.status_code == 200, response.text
    result = response.json()
    assert result["image_width"] == 1
    assert result["image_height"] == 1
    assert result["candidates"][0]["word_id"] == "mobil"
    assert result["candidates"][0]["box"] == {"x": 0.1, "y": 0.2, "width": 0.3, "height": 0.25}
    assert fake.calls == 1


def test_scene_ai_rejects_missing_consent_and_unknown_provider_word(tmp_path):
    class BadProvider(FakeSceneVision):
        def analyze(self, image, allowed_symbols):
            self.calls += 1
            return {
                "model": "bad",
                "candidates": [{"observed_label": "rahasia", "word_id": "tidak-diizinkan", "box_1000": [0, 0, 500, 500]}],
            }

    fake = BadProvider()
    client = TestClient(create_app(tmp_path / "test.db", TOKENS, scene_vision=fake))
    child_id, token, _ = link_child(client)
    url = f"/v1/children/{child_id}/scene-ai/analyze"

    assert client.post(url, headers=bearer(token), json=body(consent=False)).status_code == 422
    response = client.post(url, headers=bearer(token), json=body())
    assert response.status_code == 502
    assert "image_base64" not in response.text


def test_scene_ai_limits_attempts_per_child(tmp_path):
    fake = FakeSceneVision()
    client = TestClient(create_app(tmp_path / "test.db", TOKENS, scene_vision=fake))
    child_id, token, _ = link_child(client)
    url = f"/v1/children/{child_id}/scene-ai/analyze"

    for _ in range(10):
        assert client.post(url, headers=bearer(token), json=body()).status_code == 200
    assert client.post(url, headers=bearer(token), json=body()).status_code == 429
    assert fake.calls == 10


def test_scene_ai_drops_stacked_boxes_and_repeated_words(tmp_path):
    class StackedProvider(FakeSceneVision):
        def analyze(self, image, allowed_symbols):
            self.calls += 1
            assert allowed_symbols == [{"word_id": "mobil", "label": "MOBIL", "pos": "benda", "category": "benda"}]
            return {
                "model": "stacked",
                "candidates": [
                    {"observed_label": "mobil", "word_id": "mobil", "box_1000": [100, 100, 400, 400]},
                    {"observed_label": "roda", "word_id": None, "box_1000": [150, 150, 350, 350]},
                    {"observed_label": "mobil kedua", "word_id": "mobil", "box_1000": [600, 600, 900, 900]},
                ],
            }

    fake = StackedProvider()
    client = TestClient(create_app(tmp_path / "test.db", TOKENS, scene_vision=fake))
    child_id, token, _ = link_child(client)
    symbols = [{"word_id": "mobil", "label": "MOBIL", "pos": "benda", "category": "benda"}]
    response = client.post(f"/v1/children/{child_id}/scene-ai/analyze", headers=bearer(token), json=body(allowed_symbols=symbols))
    assert response.status_code == 200, response.text
    candidates = response.json()["candidates"]
    assert [c["observed_label"] for c in candidates] == ["mobil", "mobil kedua"]
    assert [c["word_id"] for c in candidates] == ["mobil", None]
