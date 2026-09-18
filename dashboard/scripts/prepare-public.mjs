// Menyalin konten yang dibaca dasbor ke public/ sebelum dev dan build (jalur 4, tonggak 4.1).
// Keluaran di-ignore git (.gitignore akar): public/symbols/, public/demo_events.json, public/core_vocab_id.csv.
import { cpSync, existsSync, mkdirSync, readdirSync, rmSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const dashboard = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const root = resolve(dashboard, '..')
const pub = join(dashboard, 'public')

// seed/demo_events.json dari jalur 3; sebelum ada, pakai data tiruan tangan sendiri (kontrak §7).
const seed = join(root, 'seed', 'demo_events.json')
const mock = join(dashboard, 'mock', 'demo_events.json')
const demoSource = existsSync(seed) ? seed : existsSync(mock) ? mock : null
if (!demoSource) throw new Error('Tidak ada seed/demo_events.json maupun dashboard/mock/demo_events.json')

const symbols = join(pub, 'symbols')
rmSync(symbols, { recursive: true, force: true })
mkdirSync(symbols, { recursive: true })

// symbol_file di CSV relatif ke png/ atau diawali custom/, jadi png/ disalin rata dan custom/ sebagai subfolder.
const png = join(root, 'assets', 'symbols', 'png')
const custom = join(root, 'assets', 'symbols', 'custom')
cpSync(png, symbols, { recursive: true })
mkdirSync(join(symbols, 'custom'), { recursive: true })
const customFiles = readdirSync(custom).filter((f) => f.endsWith('.png'))
for (const f of customFiles) cpSync(join(custom, f), join(symbols, 'custom', f))

cpSync(join(root, 'assets', 'vocab', 'core_vocab_id.csv'), join(pub, 'core_vocab_id.csv'))

// Font dan logo yang sama dengan aplikasi (Fredoka + Nunito, OFL), supaya dasbor tampil tanpa internet.
const appAssets = join(root, 'app', 'assets')
mkdirSync(join(pub, 'fonts'), { recursive: true })
for (const f of ['Fredoka.ttf', 'Nunito.ttf', 'OFL-Fredoka.txt', 'OFL-Nunito.txt']) cpSync(join(appAssets, 'fonts', f), join(pub, 'fonts', f))
mkdirSync(join(pub, 'brand'), { recursive: true })
cpSync(join(appAssets, 'brand', 'logo_mark.png'), join(pub, 'brand', 'logo_mark.png'))
cpSync(demoSource, join(pub, 'demo_events.json'))

const pngCount = readdirSync(png).filter((f) => f.endsWith('.png')).length
console.log(
  `prepare-public: ${pngCount} simbol png, ${customFiles.length} simbol custom, core_vocab_id.csv, font, logo, ` +
    `demo_events.json dari ${demoSource === seed ? 'seed/' : 'mock/'}`,
)
