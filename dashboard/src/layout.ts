export const centeredScrollLeft = (containerWidth: number, targetOffset: number, targetWidth: number) =>
  Math.max(0, Math.round(targetOffset - (containerWidth - targetWidth) / 2))
