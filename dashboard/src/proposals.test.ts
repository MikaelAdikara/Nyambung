import { describe, expect, it } from 'vitest'
import { proposalCounts } from './proposals'
import type { ChildRow, PhraseOut } from './types'

const child = (childId: string, pendingTargets: number): ChildRow => ({
  child_id: childId,
  nickname: childId,
  age_years: 5,
  routine: 'main',
  unique_words: 3,
  trend_3w: 'tetap',
  missions_done: 2,
  missions_total: 7,
  last_sync: null,
  pending_targets: pendingTargets,
  needs_review: false,
})

const phrase = (childId: string, status: PhraseOut['status'], createdBy = 'Bu Rina'): PhraseOut => ({
  phrase_id: `${childId}-${status}-${createdBy}`,
  child_id: childId,
  text: 'Aku mau istirahat',
  voice: 'cowo',
  word_id: 'frs-aku_mau_istirahat-12345678',
  created_by: createdBy,
  created_at: '2026-09-18T10:00:00Z',
  status,
  answered_at: null,
  used_count: 0,
})

describe('proposalCounts', () => {
  it('keeps target and therapist phrase counts separate', () => {
    const result = proposalCounts(
      [child('bima', 2), child('tiara', 0)],
      [phrase('bima', 'usulan'), phrase('bima', 'diterima'), phrase('tiara', 'usulan')],
    )

    expect(result).toMatchObject({ targets: 2, phrases: 2, total: 4 })
    expect(result.byChild.get('bima')).toEqual({ targets: 2, phrases: 1, total: 3 })
    expect(result.byChild.get('tiara')).toEqual({ targets: 0, phrases: 1, total: 1 })
  })

  it('does not count family-created spoken cards as therapist proposals', () => {
    const result = proposalCounts([child('bima', 0)], [phrase('bima', 'usulan', 'keluarga')])

    expect(result).toMatchObject({ targets: 0, phrases: 0, total: 0 })
    expect(result.byChild.get('bima')).toEqual({ targets: 0, phrases: 0, total: 0 })
  })
})
