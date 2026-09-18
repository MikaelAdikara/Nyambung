import type { ChildRow, PhraseOut } from './types'

export interface ProposalCount {
  targets: number
  phrases: number
  total: number
}

export interface ProposalCounts extends ProposalCount {
  byChild: Map<string, ProposalCount>
}

export function proposalCounts(children: ChildRow[], phrases: PhraseOut[]): ProposalCounts {
  const byChild = new Map<string, ProposalCount>()
  for (const child of children) {
    const targets = child.pending_targets
    byChild.set(child.child_id, { targets, phrases: 0, total: targets })
  }

  for (const phrase of phrases) {
    if (phrase.status !== 'usulan' || phrase.created_by === 'keluarga') continue
    const current = byChild.get(phrase.child_id) ?? { targets: 0, phrases: 0, total: 0 }
    const next = { ...current, phrases: current.phrases + 1, total: current.total + 1 }
    byChild.set(phrase.child_id, next)
  }

  const totals = [...byChild.values()].reduce(
    (sum, count) => ({
      targets: sum.targets + count.targets,
      phrases: sum.phrases + count.phrases,
      total: sum.total + count.total,
    }),
    { targets: 0, phrases: 0, total: 0 },
  )
  return { ...totals, byChild }
}
