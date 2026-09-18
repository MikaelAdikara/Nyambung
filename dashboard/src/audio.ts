export const audioPreviewError = (kind: 'api' | 'demo') =>
  kind === 'demo' ? null : 'Klip audio belum bisa dimuat atau diputar. Coba lagi; frasa yang sudah dibuat tetap tersimpan.'
