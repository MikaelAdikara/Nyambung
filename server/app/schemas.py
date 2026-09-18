"""Model masukan/keluaran API (kontrak §4).

Semua model masukan `extra="forbid"`: medan tak dikenal → 422. Ini penegakan invarian 6 di tepi API:
aplikasi hanya mengirim peristiwa mentah, tidak pernah angka agregat.
"""

from __future__ import annotations

from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

Method = Literal["SEL", "KAT", "PRS", "HAP", "UCP", "MIS", "TGT"]
Actor = Literal["anak", "pendamping"]
PromptLevel = Literal["spontan", "terpancing"]
Routine = Literal["makan", "mandi", "main"]


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


def parse_device_ts(value: str) -> datetime:
    """ISO-8601 dengan zona waktu (akhiran `Z` diterima). Tanpa zona → ValueError."""
    dt = datetime.fromisoformat(value.replace("Z", "+00:00") if value.endswith("Z") else value)
    if dt.tzinfo is None or dt.utcoffset() is None:
        raise ValueError("ts_device wajib memakai zona waktu, mis. 2026-09-18T10:15:00+07:00")
    return dt


class EventIn(StrictModel):
    event_id: str = Field(min_length=1, max_length=64)
    ts_device: str
    content: str = Field(min_length=1, max_length=2000)
    method: Method
    actor: Actor
    prompt_level: PromptLevel
    context: Optional[str] = Field(default=None, max_length=200)
    session_id: str = Field(min_length=1, max_length=64)

    @field_validator("ts_device")
    @classmethod
    def _tz_required(cls, v: str) -> str:
        parse_device_ts(v)
        return v


class SyncIn(StrictModel):
    child_id: str = Field(min_length=1, max_length=64)
    events: list[EventIn] = Field(max_length=5000)


class SyncOut(BaseModel):
    accepted: int
    duplicates: int
    rejected: list[dict] = []


class InviteOut(BaseModel):
    invite_code: str
    therapist: str


class RedeemIn(StrictModel):
    invite_code: str = Field(min_length=1, max_length=16)
    child_id: str = Field(min_length=1, max_length=64)
    nickname: str = Field(min_length=1, max_length=60)
    age_years: Optional[int] = Field(default=None, ge=0, le=30)
    routine: Routine


class RedeemOut(BaseModel):
    link_id: str
    therapist: str
    linked_at: str
    device_token: str


class LoginIn(StrictModel):
    email: str = Field(min_length=3, max_length=254)
    password: str = Field(min_length=1, max_length=200)


class LoginOut(BaseModel):
    token: str
    therapist: str
    expires_at: str


class MeOut(BaseModel):
    therapist: str
    email: Optional[str]


class TargetIn(StrictModel):
    words: list[str] = Field(min_length=1, max_length=5)
    note: Optional[str] = Field(default=None, max_length=600)
    week_index: Optional[int] = Field(default=None, ge=1, le=520)
    routine: Optional[Routine] = None

    @field_validator("words")
    @classmethod
    def _words_nonempty(cls, v: list[str]) -> list[str]:
        cleaned = [w.strip() for w in v]
        if any(not w for w in cleaned):
            raise ValueError("kata tidak boleh kosong")
        return cleaned


class TargetOut(BaseModel):
    target_id: str
    child_id: str
    words: list[str]
    note: Optional[str]
    week_index: Optional[int]
    routine: Optional[str]
    therapist: str
    created_at: str
    status: Literal["usulan", "diterima", "ditolak"]
    answered_at: Optional[str]
    used_count_since_accept: int


class SessionNoteIn(StrictModel):
    session_date: str = Field(pattern=r"^\d{4}-\d{2}-\d{2}$")
    note: str = Field(min_length=1, max_length=4000)
    focus: Optional[str] = Field(default=None, max_length=200)
    # Waktu lokal sesi berikutnya, mis. 2026-09-23T15:30 (tanpa zona: jadwal tatap muka, bukan stempel peristiwa).
    next_session: Optional[str] = Field(default=None, pattern=r"^\d{4}-\d{2}-\d{2}(T\d{2}:\d{2})?$")


class SessionShareIn(StrictModel):
    family_text: str = Field(min_length=1, max_length=1000)


class SessionNoteOut(BaseModel):
    note_id: str
    child_id: str
    therapist: str
    session_date: str
    note: str
    focus: Optional[str]
    next_session: Optional[str]
    created_at: str
    updated_at: str
    family_text: Optional[str]
    shared_at: Optional[str]


class SharedSummaryOut(BaseModel):
    """Yang diterima perangkat keluarga: hanya ringkasan yang dikirim terapis, tanpa catatan sesi."""

    summary_id: str
    therapist: str
    session_date: str
    family_text: str
    focus: Optional[str]
    next_session: Optional[str]
    shared_at: str


PhraseVoice = Literal["cowo", "cewe", "keluarga"]


class PhraseIn(StrictModel):
    text: str = Field(min_length=1, max_length=60)
    voice: PhraseVoice

    @field_validator("text")
    @classmethod
    def _clean(cls, v: str) -> str:
        cleaned = " ".join(v.split())
        if not cleaned:
            raise ValueError("frasa tidak boleh kosong")
        return cleaned


class PhraseOut(BaseModel):
    phrase_id: str
    child_id: str
    text: str
    voice: str
    word_id: str
    created_by: str
    created_at: str
    status: Literal["usulan", "diterima", "ditolak"]
    answered_at: Optional[str]
    used_count: int


class VoiceStatusOut(BaseModel):
    openai: bool
    elevenlabs: bool
    clone_active: bool
    clone_consent_by: Optional[str]
    clone_consent_at: Optional[str]


class CloneSample(StrictModel):
    filename: str = Field(min_length=1, max_length=80, pattern=r"^[\w.-]+\.(m4a|mp3|wav|ogg|aac)$")
    # ± 4 MB audio per sampel setelah base64.
    data_b64: str = Field(min_length=100, max_length=5_600_000)


class CloneIn(StrictModel):
    # Persetujuan eksplisit orang tua; nilai selain true ditolak 422.
    consent: Literal[True]
    consent_by: str = Field(min_length=1, max_length=60)
    samples: list[CloneSample] = Field(min_length=1, max_length=5)


class ReviewTimeIn(StrictModel):
    child_id: str = Field(min_length=1, max_length=64)
    seconds: int = Field(ge=5, le=3600)
