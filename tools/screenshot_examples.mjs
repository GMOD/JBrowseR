// Render the built htmlwidget bundles headless with a fake HTMLWidgets host and
// screenshot them, so the README figures show the widget actually working (and
// so we verify the bundle renders). Reads tools/screenshot_specs.json (from
// gen_screenshot_specs.R); writes man/figures/<name>.png.
//
// puppeteer resolves from the sibling jbrowse-components checkout (override with
// PUPPETEER_FROM=/path/to/pkg-dir). Run:  node tools/screenshot_examples.mjs
import { createServer } from 'node:http'
import { mkdir, readFile } from 'node:fs/promises'
import { basename, extname, join } from 'node:path'
import { createRequire } from 'node:module'

const REPO = new URL('..', import.meta.url).pathname
const from =
  process.env.PUPPETEER_FROM ??
  new URL('../../jbrowse-components/package.json', import.meta.url).pathname
const puppeteer = createRequire(from)('puppeteer')

const specs = JSON.parse(
  await readFile(join(REPO, 'tools/screenshot_specs.json'), 'utf8'),
)

const TYPES = { '.js': 'text/javascript', '.css': 'text/css', '.html': 'text/html' }

// A page that fakes just enough of the HTMLWidgets host to register the widget
// (window.HTMLWidgets.widget captures the definition), then drives its factory's
// renderValue with the payload from window.__x — the same x an R JBrowseR()
// call would hand it.
function harness(bundle) {
  const css = basename(bundle, '.js') + '.css'
  return `<!doctype html><html><head><meta charset="utf8">
<link rel="stylesheet" href="/inst/htmlwidgets/${css}">
<style>html,body{margin:0}#root{width:1000px}</style>
<script>window.HTMLWidgets={widget:d=>{window.__widget=d}}</script>
<script src="/inst/htmlwidgets/${bundle}"></script></head><body>
<div id="root"></div>
<script>
const el = document.getElementById('root')
const inst = window.__widget.factory(el, el.clientWidth, 700)
inst.renderValue(window.__x)
window.__rendered = true
</script></body></html>`
}

const server = createServer(async (req, res) => {
  const url = new URL(req.url, 'http://localhost')
  const bundle = url.searchParams.get('bundle')
  if (url.pathname === '/harness.html' && bundle) {
    res.setHeader('content-type', 'text/html')
    res.end(harness(bundle))
  } else {
    try {
      const body = await readFile(join(REPO, url.pathname))
      res.setHeader('content-type', TYPES[extname(url.pathname)] ?? 'application/octet-stream')
      res.end(body)
    } catch {
      res.statusCode = 404
      res.end('not found')
    }
  }
})
await new Promise(r => server.listen(0, r))
const port = server.address().port

await mkdir(join(REPO, 'man/figures'), { recursive: true })
const browser = await puppeteer.launch({
  headless: true,
  args: [
    '--no-sandbox',
    '--enable-unsafe-swiftshader',
    '--use-gl=angle',
    '--use-angle=swiftshader',
    '--ignore-gpu-blocklist',
  ],
})

let failed = 0
for (const [name, spec] of Object.entries(specs)) {
  const tall = spec.bundle === 'JBrowseRApp.js'
  const page = await browser.newPage()
  await page.setViewport({ width: 1000, height: tall ? 760 : 440, deviceScaleFactor: 2 })
  const errors = []
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
    failed++
    await page.close()
    continue
  }
  // wait out any in-progress download (a forceLoad'd dense region can take a
  // while), then settle so the GPU/canvas paint lands
  await page
    .waitForFunction(() => !document.body.innerText.includes('Downloading'), {
      timeout: 90000,
    })
    .catch(() => {})
  await new Promise(r => setTimeout(r, 6000))
  await page.screenshot({ path: join(REPO, 'man/figures', `${name}.png`) })
  console.log(`✓ ${name} -> man/figures/${name}.png${errors.length ? `  (${errors.length} page errors)` : ''}`)
  if (errors.length) console.error('  ', errors.slice(0, 2).join(' | '))
  await page.close()
}

await browser.close()
server.close()
process.exit(failed ? 1 : 0)
