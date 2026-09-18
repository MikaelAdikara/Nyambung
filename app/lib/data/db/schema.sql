CREATE TABLE IF NOT EXISTS child (
  child_id   TEXT PRIMARY KEY,         -- uuid v4 dibuat di perangkat
  nickname   TEXT NOT NULL,
  age_years  INTEGER,                  -- hanya untuk ukuran sel, bukan penyaring kosakata
  grid_cols  INTEGER NOT NULL DEFAULT 3,
  routine    TEXT NOT NULL,            -- makan | mandi | main
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS symbol (
  word_id        TEXT PRIMARY KEY,
  label_display  TEXT NOT NULL,        -- HURUF KAPITAL
  label_speech   TEXT NOT NULL,
  pos            TEXT NOT NULL,        -- pengatur|kerja|ganti|sifat|tanya|benda|sosial
  category       TEXT NOT NULL,
  page           INTEGER NOT NULL,     -- 0 = kata inti
  position_index INTEGER NOT NULL,     -- TIDAK PERNAH BERUBAH
  symbol_path    TEXT NOT NULL,
  audio_path     TEXT,
  family_audio   TEXT,                 -- tidak pernah disinkronkan
  is_hidden      INTEGER NOT NULL DEFAULT 0,
  is_custom      INTEGER NOT NULL DEFAULT 0,
  UNIQUE (page, position_index)
);

-- APPEND-ONLY
CREATE TABLE IF NOT EXISTS utterance_event (
  event_id     TEXT PRIMARY KEY,       -- uuid v4
  child_id     TEXT NOT NULL,
  ts_device    TEXT NOT NULL,          -- ISO-8601 DENGAN zona waktu, mis. 2026-09-18T10:15:00+07:00
  content      TEXT NOT NULL,
  method       TEXT NOT NULL,          -- lihat §3
  actor        TEXT NOT NULL,          -- anak | pendamping
  prompt_level TEXT NOT NULL,          -- spontan | terpancing
  context      TEXT,
  session_id   TEXT NOT NULL,
  synced_at    TEXT                    -- satu-satunya kolom yang boleh di-UPDATE
);

CREATE TABLE IF NOT EXISTS outbox (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  event_id    TEXT NOT NULL REFERENCES utterance_event(event_id),
  attempts    INTEGER NOT NULL DEFAULT 0,
  next_try_at TEXT
);

CREATE TABLE IF NOT EXISTS mission (
  mission_id  TEXT PRIMARY KEY,
  week_index  INTEGER NOT NULL,
  target_word TEXT NOT NULL REFERENCES symbol(word_id),
  routine     TEXT NOT NULL,
  reps_target INTEGER NOT NULL DEFAULT 5,
  lesson_key  TEXT
);

CREATE TABLE IF NOT EXISTS mission_log (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  mission_id   TEXT NOT NULL,
  date         TEXT NOT NULL,
  status       TEXT NOT NULL,          -- selesai | belum_sempat
  reps_counted INTEGER NOT NULL DEFAULT 0,  -- dihitung dari ketukan, bukan isian
  UNIQUE (mission_id, date)
);

CREATE TABLE IF NOT EXISTS therapist_link (
  link_id     TEXT PRIMARY KEY,
  invite_code TEXT NOT NULL,
  therapist   TEXT,
  linked_at   TEXT,
  revoked_at  TEXT
);

CREATE TABLE IF NOT EXISTS vocab_target (
  target_id   TEXT PRIMARY KEY,
  words       TEXT NOT NULL,           -- JSON array word_id
  note        TEXT,
  week_index  INTEGER,
  status      TEXT NOT NULL,           -- usulan | diterima | ditolak
  received_at TEXT
);

-- Ringkasan sesi yang dikirim terapis ke keluarga (C5). Hanya teks untuk keluarga; catatan sesi terapis tidak
-- pernah sampai ke perangkat. Ditarik saat sinkron, ditimpa bila terapis mengirim ulang.
CREATE TABLE IF NOT EXISTS therapist_summary (
  summary_id   TEXT PRIMARY KEY,
  therapist    TEXT,
  session_date TEXT NOT NULL,
  family_text  TEXT NOT NULL,
  focus        TEXT,
  next_session TEXT,
  shared_at    TEXT NOT NULL
);

-- Frasa bersuara: teks bebas + klip yang dibuat sekali di server (OpenAI atau klon suara keluarga), diunduh ke
-- folder aplikasi `phrases/`, lalu diputar luring. Frasa dari terapis berstatus usulan sampai keluarga menjawab (TGT).
CREATE TABLE IF NOT EXISTS phrase (
  phrase_id  TEXT PRIMARY KEY,
  text       TEXT NOT NULL,
  voice      TEXT NOT NULL,            -- cowo | cewe | keluarga
  created_by TEXT NOT NULL,            -- keluarga | nama terapis
  created_at TEXT NOT NULL,
  status     TEXT NOT NULL,            -- usulan | diterima | ditolak
  audio_path TEXT                      -- null sampai klip terunduh
);

-- Penegakan invarian 3: isi peristiwa tidak berubah, tidak dihapus.
CREATE TRIGGER IF NOT EXISTS utterance_no_update BEFORE UPDATE OF
  event_id, child_id, ts_device, content, method, actor, prompt_level, context, session_id
  ON utterance_event
BEGIN SELECT RAISE(ABORT, 'utterance_event append-only'); END;
CREATE TRIGGER IF NOT EXISTS utterance_no_delete BEFORE DELETE ON utterance_event
BEGIN SELECT RAISE(ABORT, 'utterance_event append-only'); END;

CREATE INDEX IF NOT EXISTS idx_event_child_ts ON utterance_event(child_id, ts_device);
CREATE INDEX IF NOT EXISTS idx_event_unsynced ON utterance_event(synced_at) WHERE synced_at IS NULL;
