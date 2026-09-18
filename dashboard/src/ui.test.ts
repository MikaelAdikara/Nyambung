import { describe, expect, it } from 'vitest'
import { centeredScrollLeft } from './layout'

describe('centeredScrollLeft', () => {
  it('centers the active child tab inside a narrow tab strip', () => {
    expect(centeredScrollLeft(348, 280, 135)).toBe(174)
  })

  it('does not request negative scroll for the first tab', () => {
    expect(centeredScrollLeft(348, 5, 120)).toBe(0)
  })
})
