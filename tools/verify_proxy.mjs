// End-to-end check of the `jbrowse_proxy()` wire, against the built bundle.
//
// `tests/testthat/test-proxy.R` pins what R sends; this pins what the bundle
// does with it. Between them the contract has both ends nailed down, which
// matters because the seam is a string ("jbrowser-call") and a plain object —
// nothing typed crosses it, so a rename on one side is silent on the other.
//
// It drives the same fake-HTMLWidgets harness as screenshot_examples.mjs, plus
// a fake Shiny that records setInputValue calls and hands back the custom
// message handler the bundle registers. Three things get exercised that a unit
// test cannot reach: the handler is registered at all, a call that lands
// mid-build still arrives (the registry holds the build promise, not the
// controller), and the view actually moves.
//
// Needs network — it loads the hosted hg38 hub, same as the figures do.
//
// puppeteer resolves from the sibling jbrowse-components checkout (override
// with PUPPETEER_FROM=/path/to/pkg-dir). Run:  node tools/verify_proxy.mjs
import { createServer } from 'node:http'
import { readFile } from 'node:fs/promises'
import { basename, extname, join } from 'node:path'
import { createRequire } from 'node:module'

const REPO = new URL('..', import.meta.url).pathname
const from =
  process.env.PUPPETEER_FROM ??
  new URL('../../jbrowse-components/package.json', import.meta.url).pathname
const puppeteer = createRequire(from)('puppeteer')

const TYPES = {
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.html': 'text/html',
}

// The widget renders into an element whose id is what a Shiny outputId becomes,
// so the proxy call has something to name.
const OUTPUT_ID = 'browserOutput'
const START = '10:29,838,737..29,838,819'
const TARGET = '17:43,044,295..43,125,483'

// Same shape as the screenshot harness, with a Shiny stub added: the bundle
// registers its handler through addCustomMessageHandler, and reports back
// through setInputValue, so both directions are observable from the page.
function harness(bundle) {
  const css = `${basename(bundle, '.js')}.css`
  return `<!doctype html><html><head><meta charset="utf8">
<link rel="stylesheet" href="/inst/htmlwidgets/${css}">
<style>html,body{margin:0}#${OUTPUT_ID}{width:1000px}</style>
<script>
window.HTMLWidgets = { widget: d => { window.__widget = d } }
window.__inputs = {}
window.__handlers = {}
window.Shiny = {
  setInputValue: (id, value) => { window.__inputs[id] = value },
  addCustomMessageHandler: (type, handler) => { window.__handlers[type] = handler },
}
</script>
<script src="/inst/htmlwidgets/${bundle}"></script></head><body>
<div id="${OUTPUT_ID}"></div>
<script>
const el = document.getElementById(${JSON.stringify(OUTPUT_ID)})
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
      res.setHeader(
        'content-type',
        TYPES[extname(url.pathname)] ?? 'application/octet-stream',
      )
      res.end(body)
    } catch {
      res.statusCode = 404
      res.end('not found')
    }
  }
})
await new Promise(r => {
  server.listen(0, r)
})
const port = server.address().port

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

const failures = []
function check(ok, what) {
  console.log(`${ok ? '✓' : '✗'} ${what}`)
  if (!ok) {
    failures.push(what)
  }
}

const page = await browser.newPage()
const errors = []
page.on('pageerror', e => {
  errors.push(String(e))
})
try {
  await page.setViewport({ width: 1000, height: 440 })
  await page.evaluateOnNewDocument(
    x => {
      window.__x = x
    },
    { assembly: 'hg38', location: START },
  )
  await page.goto(`http://localhost:${port}/harness.html?bundle=JBrowseR.js`, {
    waitUntil: 'load',
    timeout: 60000,
  })

  // Sent immediately after renderValue, while createLinearGenomeView is still
  // resolving. This is the race an `observe()` at app startup hits, and the
  // reason the registry holds the build promise: a caller keyed to the resolved
  // controller would drop this call with the browser looking fine.
  await page.waitForFunction(() => window.__rendered === true, {
    timeout: 30000,
  })
  const registered = await page.evaluate(
    () => typeof window.__handlers['jbrowser-call'] === 'function',
  )
  check(registered, 'the bundle registers a jbrowser-call handler')

  await page.evaluate(
    (id, location) => {
      window.__handlers['jbrowser-call']({
        id,
        method: 'setLocation',
        args: { location },
      })
    },
    OUTPUT_ID,
    TARGET,
  )

  // The location read-back is the assertion: the view reports where it ended up
  // through the same onLocationChange the Shiny input rides, so this proves the
  // navigation happened rather than that the call was accepted.
  //
  // It comes back as `chr17:…` though `17:…` was sent, because the reported
  // refName is the assembly's and the hub's hg38 spells it `chr17`. JBrowse
  // aliases the two, so this is what a Shiny app comparing strings sees too —
  // the trap the HANDOFF's `_location` note is about, asserted here rather than
  // only described.
  const landed = await page
    .waitForFunction(
      id => /^(chr)?17:/.test(window.__inputs[`${id}_location`] ?? ''),
      { timeout: 90000 },
      OUTPUT_ID,
    )
    .then(() => true)
    .catch(() => false)
  const reported = await page.evaluate(
    id => window.__inputs[`${id}_location`],
    OUTPUT_ID,
  )
  check(landed, `a mid-build setLocation lands (reported "${reported}")`)

  // An id that names no rendered widget must not throw: a Shiny handler that
  // throws is not obviously fatal, but it leaves the page's message channel in
  // a state nothing else on the page can diagnose.
  const unknownIdThrew = await page.evaluate(() => {
    try {
      window.__handlers['jbrowser-call']({
        id: 'not-a-widget',
        method: 'setLocation',
        args: { location: '1:1-100' },
      })
      return false
    } catch {
      return true
    }
  })
  check(!unknownIdThrew, 'a call naming no rendered widget is ignored, not thrown')

  const clickable = await page.evaluate(() => 'selectedFeature' in window.__inputs)
  check(!clickable, 'no global selectedFeature input is set')
} finally {
  await page.close()
  await browser.close()
  server.close()
}

if (errors.length) {
  console.error('page errors:', errors.slice(0, 5).join(' | '))
}
if (failures.length) {
  console.error(`\n${failures.length} check(s) failed`)
  process.exit(1)
}
console.log('\nproxy wire verified')
