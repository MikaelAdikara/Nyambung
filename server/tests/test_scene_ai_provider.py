import json

from app.services.scene_ai import HttpSceneVisionProvider


class FakeResponse:
    def __enter__(self):
        return self

    def __exit__(self, *_):
        return None

    def read(self):
        provider_json = {"candidates": [{"observed_label": "mobil", "word_id": "mobil", "box_1000": [0, 0, 500, 500]}]}
        return json.dumps({"candidates": [{"content": {"parts": [{"text": json.dumps(provider_json)}]}}]}).encode()


def test_http_provider_keeps_key_in_header_and_requests_structured_json(monkeypatch):
    monkeypatch.setenv("GEMINI_API_KEY", "secret-test-key")
    monkeypatch.setenv("NYAMBUNG_VISION_MODEL", "configured-model")
    captured = {}

    def fake_open(request, timeout):
        captured["request"] = request
        captured["timeout"] = timeout
        return FakeResponse()

    monkeypatch.setattr("urllib.request.urlopen", fake_open)
    result = HttpSceneVisionProvider().analyze(b"jpeg", [{"word_id": "mobil", "label": "MOBIL"}])

    request = captured["request"]
    payload = json.loads(request.data)
    assert "secret-test-key" not in request.full_url
    assert request.headers["X-goog-api-key"] == "secret-test-key"
    assert payload["generationConfig"]["responseMimeType"] == "application/json"
    assert payload["generationConfig"]["responseJsonSchema"]["properties"]["candidates"]["maxItems"] == 6
    assert result["model"] == "configured-model"
    assert result["candidates"][0]["word_id"] == "mobil"


class FakeOpenAIResponse(FakeResponse):
    def read(self):
        provider_json = {"candidates": [{"observed_label": "bola", "word_id": "bola", "box_1000": [100, 100, 400, 400]}]}
        return json.dumps(
            {"model": "gpt-test", "output": [{"type": "message", "content": [{"type": "output_text", "text": json.dumps(provider_json)}]}]}
        ).encode()


def test_openai_is_used_when_gemini_is_not_configured(monkeypatch):
    monkeypatch.setattr("app.services.scene_ai._env_key", lambda name: {"OPENAI_API_KEY": "sk-test-key"}.get(name))
    captured = {}

    def fake_open(request, timeout):
        captured["request"] = request
        return FakeOpenAIResponse()

    monkeypatch.setattr("urllib.request.urlopen", fake_open)
    provider = HttpSceneVisionProvider()
    assert provider.available() and provider.name() == "openai"
    result = provider.analyze(b"jpeg", [{"word_id": "bola", "label": "BOLA"}])

    request = captured["request"]
    payload = json.loads(request.data)
    assert request.full_url == "https://api.openai.com/v1/responses"
    assert request.headers["Authorization"] == "Bearer sk-test-key"
    assert payload["store"] is False
    assert payload["text"]["format"]["strict"] is True
    assert payload["input"][0]["content"][1]["image_url"].startswith("data:image/jpeg;base64,")
    assert result == {"candidates": [{"observed_label": "bola", "word_id": "bola", "box_1000": [100, 100, 400, 400]}], "model": "gpt-test", "provider": "openai"}
