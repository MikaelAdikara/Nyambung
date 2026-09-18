import { describe, expect, it } from 'vitest'
import { parseHash } from './route'

describe('parseHash', () => {
  it.each([
    ['', { page: 'D1' }],
    ['#/', { page: 'D1' }],
    ['#/anak/bima', { page: 'D2', childId: 'bima' }],
    ['#/anak/bima/target', { page: 'D3', childId: 'bima' }],
    ['#/anak/bima/sesi', { page: 'D4', childId: 'bima' }],
    ['#/anak/bima/frasa', { page: 'D5', childId: 'bima' }],
    ['#/anak/Bima%20Putra', { page: 'D2', childId: 'Bima Putra' }],
  ])('maps %s to the expected dashboard route', (hash, route) => {
    expect(parseHash(hash)).toEqual(route)
  })

  it('keeps unknown paths explicit', () => {
    expect(parseHash('#/tidak-ada')).toEqual({ page: 'unknown', hash: '#/tidak-ada' })
  })
})
