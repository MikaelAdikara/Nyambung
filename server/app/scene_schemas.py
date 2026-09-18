"""Kontrak API untuk draf visual-scene. Foto tidak pernah disimpan server."""

from typing import Literal, Optional

from pydantic import Field, field_validator

from .schemas import StrictModel


class AllowedSymbol(StrictModel):
    word_id: str = Field(min_length=1, max_length=100)
    label: str = Field(min_length=1, max_length=60)
    pos: Optional[str] = Field(default=None, max_length=30)
    category: Optional[str] = Field(default=None, max_length=30)


class SceneAnalyzeIn(StrictModel):
    consent: Literal[True]
    image_mime: Literal["image/jpeg"]
    image_base64: str = Field(min_length=16, max_length=2_800_000)
    allowed_symbols: list[AllowedSymbol] = Field(min_length=1, max_length=200)

    @field_validator("allowed_symbols")
    @classmethod
    def unique_ids(cls, value: list[AllowedSymbol]) -> list[AllowedSymbol]:
        ids = [item.word_id for item in value]
        if len(ids) != len(set(ids)):
            raise ValueError("word_id harus unik")
        return value


class SceneBoxOut(StrictModel):
    x: float = Field(ge=0, le=1)
    y: float = Field(ge=0, le=1)
    width: float = Field(gt=0, le=1)
    height: float = Field(gt=0, le=1)


class SceneCandidateOut(StrictModel):
    id: str
    observed_label: str
    word_id: Optional[str] = None
    box: SceneBoxOut


class SceneAnalyzeOut(StrictModel):
    request_id: str
    provider: Literal["google", "openai"] = "google"
    model: str
    image_width: int
    image_height: int
    candidates: list[SceneCandidateOut]
    warnings: list[str] = []
