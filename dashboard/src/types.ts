// Bentuk JSON persis kontrak §4 (API) dan §7 (berkas data demo).

export type Routine = 'makan' | 'mandi' | 'main'
export type Trend = 'naik' | 'tetap' | 'turun' | 'baru'
export type TargetStatus = 'usulan' | 'diterima' | 'ditolak'

export interface ChildRow {
  child_id: string
  nickname: string | null
  age_years: number | null
  routine: string | null
  unique_words: number
  trend_3w: Trend
  missions_done: number
  missions_total: number
  last_sync: string | null
  pending_targets: number
  needs_review: boolean
}

export interface ChildrenOverview {
  // Rerata lama satu tinjauan (menit), 30 hari terakhir; null = belum diukur
  review_avg_minutes: number | null
  review_count_30d: number
  active_families: number
  needs_review: number
  unsynced_over_7d: number
  pending_targets: number
  children: ChildRow[]
}

export interface WordCount {
  word: string
  count: number
}

export interface Summary {
  child_id: string
  nickname: string | null
  age_years: number | null
  routine: string | null
  days: number
  window_start_utc: string
  window_end_utc: string
  unique_words: number
  unique_words_prev: number
  spontaneous_ratio: number | null
  missions_done: number
  missions_total: number
  top_words: WordCount[]
  hour_histogram: number[]
  last_sync: string | null
  trend_3w: Trend
  total_taps: number
  parent_taps: number
  child_taps: number
  prompted_taps: number
  spontaneous_taps: number
  missions_skipped: number
  weekly_unique_6w: number[]
  missions_done_6w: number
  missions_total_6w: number
  word_counts: Record<string, number>
  linked_weeks: number | null
  pending_targets: number
}

export interface TargetIn {
  words: string[]
  note?: string
  week_index?: number
  routine?: Routine
}

export interface TargetOut {
  target_id: string
  child_id: string
  words: string[]
  note: string | null
  week_index: number | null
  routine: string | null
  therapist: string
  created_at: string
  status: TargetStatus
  answered_at: string | null
  used_count_since_accept: number
}

// D4: catatan sesi milik terapis. Keluarga hanya menerima family_text setelah dikirim.
export interface SessionNoteIn {
  session_date: string
  note: string
  focus?: string
  next_session?: string
}

export interface SessionNote {
  note_id: string
  child_id: string
  therapist: string
  session_date: string
  note: string
  focus: string | null
  next_session: string | null
  created_at: string
  updated_at: string
  family_text: string | null
  shared_at: string | null
}

export interface InviteOut {
  invite_code: string
  therapist: string
}

// Kontrak §7
export interface DemoEvent {
  child_id: string
  event_id: string
  ts_device: string
  content: string
  method: string
  actor: string
  prompt_level: string
  context: string | null
  session_id: string
}

export interface DemoChild {
  child_id: string
  nickname: string
  age_years: number | null
  routine: string
  linked_at: string | null
  last_sync: string | null
}

export interface DemoTarget {
  target_id: string
  child_id: string
  words: string[]
  note: string | null
  week_index: number | null
  routine: string | null
  therapist: string
  created_at: string
}

export interface DemoFile {
  illustrative: boolean
  generated_at: string
  children: DemoChild[]
  events: DemoEvent[]
  targets: DemoTarget[]
  // Catatan sesi ilustratif (D4); berkas lama tanpa medan ini tetap sah
  sessions?: SessionNote[]
}

// Satu baris assets/vocab/core_vocab_id.csv (hanya kolom yang dipakai dasbor)
export interface VocabWord {
  word_id: string
  label_display: string
  pos: string
  category: string
  page: number
  position_index: number
  symbol_file: string
}

// Frasa bersuara: teks + klip yang dibuat server sekali (OpenAI atau tiruan suara keluarga), diputar luring di HP.
export type PhraseVoice = 'cowo' | 'cewe' | 'keluarga'

export interface PhraseOut {
  phrase_id: string
  child_id: string
  text: string
  voice: PhraseVoice
  word_id: string
  // 'keluarga' atau nama terapis
  created_by: string
  created_at: string
  status: TargetStatus
  answered_at: string | null
  used_count: number
}

export interface VoiceStatus {
  openai: boolean
  elevenlabs: boolean
  clone_active: boolean
  clone_consent_by: string | null
  clone_consent_at: string | null
}

// Misi harian per (tanggal lokal, mission_id). Dihitung dari peristiwa mentah (server summary.mission_rows).
export interface MissionDay {
  date: string
  mission_id: string
  week: number | null
  word: string | null
  // terapis = kata dari usulan yang sudah diterima keluarga; bawaan = urutan kata inti per rutinitas di aplikasi
  source: 'terapis' | 'bawaan'
  status: 'selesai' | 'belum_sempat' | null
  parent_taps: number
  child_taps: number
}
