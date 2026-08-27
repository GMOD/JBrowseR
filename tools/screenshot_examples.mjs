// Render the built htmlwidget bundles headless with a fake htmlwidgets host and
// screenshot them, so the README figures show the widget actually working (and
// so we verify the bundle renders). Reads tools/screenshot_specs.json (from
// gen_screenshot_specs.R); writes man/figures/<name>.png.
//
// puppeteer resolves from the sibling jbrowse-components checkout (override with
// PUPPETEER_FROM=/path/to/pkg-dir). Run:  node tools/screenshot_examples.mjs
import { mkdir, readFile } from 'node:fs/promises'
import { join } from 'node:path'

import {
  REPO,
  htmlwidgetsHost,
  launch,
  serveRepo,
  waitForReady,
} from './browser_harness.mjs'

const specs = JSON.parse(
  await readFile(join(REPO, 'tools/screenshot_specs.json'), 'utf8'),
)

const { port, close } = await serveRepo(bundle => htmlwidgetsHost(bundle))

await mkdir(join(REPO, 'man/figures'), { recursive: true })
const browser = await launch()

// Render one spec in a fresh page and write its figure. Returns the page errors
// it collected, or null when the widget never painted a canvas at all.
async function capture(name, spec) {
  const tall = spec.bundle === 'JBrowseRApp.js'
  const page = await browser.newPage()
  const errors = []
  try {
    await page.setViewport({
      width: 1000,
      height: tall ? 760 : 440,
      deviceScaleFactor: 2,
    })
    page.on('pageerror', e => errors.push(String(e)))
    await page.evaluateOnNewDocument(x => { window.__x = x }, spec.x)
    await page.goto(`http://localhost:${port}/harness.html?bundle=${spec.bundle}`, {
      waitUntil: 'load',
      timeout: 60000,
    })
    try {
      await page.waitForFunction(() => window.__rendered === true, { timeout: 30000 })
      await page.waitForSelector('#root canvas', { timeout: 45000 })
    } catch (e) {
      console.error(`✗ ${name}: never rendered — ${e.message}`)
      if (errors.length) console.error('  page errors:', errors.slice(0, 3).join(' | '))
      return null
    }
    await waitForReady(page)
    await page.screenshot({ path: join(REPO, 'man/figures', `${name}.png`) })
    return errors
  } finally {
    await page.close()
  }
}

// name arguments re-shoot just those figures: node tools/screenshot_examples.mjs demo-dotplot
const only = new Set(process.argv.slice(2))
let failed = 0

for (const [name, spec] of Object.entries(specs)) {
  if (only.size && !only.has(name)) {
    continue
  }
  const errors = await capture(name, spec)
  if (errors === null) {
    failed++
  } else {
    console.log(`✓ ${name} -> man/figures/${name}.png${errors.length ? `  (${errors.length} page errors)` : ''}`)
    if (errors.length) console.error('  ', errors.slice(0, 2).join(' | '))
  }
}

await browser.close()
close()
process.exit(failed ? 1 : 0)
