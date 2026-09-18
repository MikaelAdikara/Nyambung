import { describe, expect, it } from 'vitest'
import { audioPreviewError } from '../audio'

describe('audioPreviewError', () => {
  it('gives API users a recoverable preview message', () => {
    expect(audioPreviewError('api')).toContain('Coba lagi')
  })

  it('keeps demo mode read-only without presenting a false failure', () => {
    expect(audioPreviewError('demo')).toBeNull()
  })
})
