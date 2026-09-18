/// Salinan `schema.sql` sebagai daftar pernyataan, karena `sqflite.execute` hanya menerima satu
/// pernyataan dan trigger `BEGIN … END;` berisi titik koma (jadi tidak boleh `split(';')`).
///
/// Sumber tunggal tetap `schema.sql`. Ubah di sana, salin ke sini, jalankan `flutter test`:
/// `test/vocab_and_board_test.dart` memastikan keduanya identik.
library;

/// v2: tabel `therapist_summary` (C5). v3: tabel `phrase`. v4: papan foto.
/// Pemutakhiran menjalankan ulang semua pernyataan `IF NOT EXISTS`.
const schemaVersion = 4;

const schemaStatements = <String>[
  '''
CREATE TABLE IF NOT EXISTS child (
  child_id   TEXT PRIMARY KEY,
  nickname   TEXT NOT NULL,
  age_years  INTEGER,
  grid_cols  INTEGER NOT NULL DEFAULT 3,
  routine    TEXT NOT NULL,
  created_at TEXT NOT NULL
)''',
  '''
CREATE TABLE IF NOT EXISTS symbol (
  word_id        TEXT PRIMARY KEY,
  label_display  TEXT NOT NULL,
  label_speech   TEXT NOT NULL,
  pos            TEXT NOT NULL,
  category       TEXT NOT NULL,
  page           INTEGER NOT NULL,
  position_index INTEGER NOT NULL,
  symbol_path    TEXT NOT NULL,
  audio_path     TEXT,
  family_audio   TEXT,
  is_hidden      INTEGER NOT NULL DEFAULT 0,
  is_custom      INTEGER NOT NULL DEFAULT 0,
  UNIQUE (page, position_index)
)''',
  '''
CREATE TABLE IF NOT EXISTS utterance_event (
  event_id     TEXT PRIMARY KEY,
  child_id     TEXT NOT NULL,
  ts_device    TEXT NOT NULL,
  content      TEXT NOT NULL,
  method       TEXT NOT NULL,
  actor        TEXT NOT NULL,
  prompt_level TEXT NOT NULL,
  context      TEXT,
  session_id   TEXT NOT NULL,
  synced_at    TEXT
)''',
  '''
CREATE TABLE IF NOT EXISTS outbox (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  event_id    TEXT NOT NULL REFERENCES utterance_event(event_id),
  attempts    INTEGER NOT NULL DEFAULT 0,
  next_try_at TEXT
)''',
  '''
CREATE TABLE IF NOT EXISTS mission (
  mission_id  TEXT PRIMARY KEY,
  week_index  INTEGER NOT NULL,
  target_word TEXT NOT NULL REFERENCES symbol(word_id),
  routine     TEXT NOT NULL,
  reps_target INTEGER NOT NULL DEFAULT 5,
  lesson_key  TEXT
)''',
  '''
CREATE TABLE IF NOT EXISTS mission_log (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  mission_id   TEXT NOT NULL,
  date         TEXT NOT NULL,
  status       TEXT NOT NULL,
  reps_counted INTEGER NOT NULL DEFAULT 0,
  UNIQUE (mission_id, date)
)''',
  '''
CREATE TABLE IF NOT EXISTS therapist_link (
  link_id     TEXT PRIMARY KEY,
  invite_code TEXT NOT NULL,
  therapist   TEXT,
  linked_at   TEXT,
  revoked_at  TEXT
)''',
  '''
CREATE TABLE IF NOT EXISTS vocab_target (
  target_id   TEXT PRIMARY KEY,
  words       TEXT NOT NULL,
  note        TEXT,
  week_index  INTEGER,
  status      TEXT NOT NULL,
  received_at TEXT
)''',
  '''
CREATE TABLE IF NOT EXISTS therapist_summary (
  summary_id   TEXT PRIMARY KEY,
  therapist    TEXT,
  session_date TEXT NOT NULL,
  family_text  TEXT NOT NULL,
  focus        TEXT,
  next_session TEXT,
  shared_at    TEXT NOT NULL
)''',
  '''
CREATE TABLE IF NOT EXISTS phrase (
  phrase_id  TEXT PRIMARY KEY,
  text       TEXT NOT NULL,
  voice      TEXT NOT NULL,
  created_by TEXT NOT NULL,
  created_at TEXT NOT NULL,
  status     TEXT NOT NULL,
  audio_path TEXT
)''',
  '''
CREATE TABLE IF NOT EXISTS scene_board (
  scene_id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES child(child_id),
  title TEXT NOT NULL,
  image_path TEXT NOT NULL,
  image_width INTEGER NOT NULL,
  image_height INTEGER NOT NULL,
  revision INTEGER NOT NULL DEFAULT 1,
  payload_json TEXT NOT NULL,
  source TEXT NOT NULL CHECK(source IN ('manual','ai')),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT
)''',
  'CREATE INDEX IF NOT EXISTS idx_scene_child ON scene_board(child_id, archived_at)',
  '''
CREATE TABLE IF NOT EXISTS scene_draft (
  draft_id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES child(child_id),
  scene_id TEXT,
  title TEXT NOT NULL,
  image_path TEXT,
  payload_json TEXT NOT NULL,
  updated_at TEXT NOT NULL
)''',
  '''
CREATE TRIGGER IF NOT EXISTS utterance_no_update BEFORE UPDATE OF
  event_id, child_id, ts_device, content, method, actor, prompt_level, context, session_id
  ON utterance_event
BEGIN SELECT RAISE(ABORT, 'utterance_event append-only'); END''',
  '''
CREATE TRIGGER IF NOT EXISTS utterance_no_delete BEFORE DELETE ON utterance_event
BEGIN SELECT RAISE(ABORT, 'utterance_event append-only'); END''',
  'CREATE INDEX IF NOT EXISTS idx_event_child_ts ON utterance_event(child_id, ts_device)',
  'CREATE INDEX IF NOT EXISTS idx_event_unsynced ON utterance_event(synced_at) WHERE synced_at IS NULL',
];

/// Normalisasi untuk membandingkan `schema.sql` dengan [schemaStatements]:
/// buang komentar `--`, satukan spasi.
String normalizeSql(String sql) =>
    sql.split('\n').map((l) => l.contains('--') ? l.substring(0, l.indexOf('--')) : l).join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
