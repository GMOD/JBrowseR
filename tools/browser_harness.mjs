// What screenshot_examples.mjs and verify_widget.mjs both need: puppeteer out of
// the sibling jbrowse-components checkout, a static server over this repo, a
// browser that renders WebGL with no GPU, and a page that fakes the htmlwidgets
// host. Shared because the two copies of it had already drifted — one had the
// launch flags, the other a stale import path for the readiness waits.

import { readFile } from 'node:fs/promises'
import { createServer } from 'node:http'
import { createRequire } from 'node:module'
import { basename, extname, join } from 'node:path'

// puppeteer isn't a dep of this repo; resolve it from the sibling
// jbrowse-components checkout (override with PUPPETEER_FROM=/path/to/pkg-dir).
export const MONOREPO =
  process.env.PUPPETEER_FROM ??
  new URL('../../jbrowse-components/package.json', import.meta.url).pathname

export const puppeteer = createRequire(MONOREPO)('puppeteer')

/** Resolve a path inside that checkout, for importing its source directly. */
export const fromMonorepo = subpath =>
  new URL(subpath, `file://${MONOREPO}`).href

// The readiness waits and the chrome-picking come from @jbrowse/capture, the
// published half of that checkout's browser tooling. They used to be imported
// from packages/browser-test-utils/src/waits.ts, which no longer exists — the
// nightly render job died at that import with ERR_MODULE_NOT_FOUND.
//
// findChromeExecutable is CHROME_PATH, then the first installed system browser,
// then puppeteer's own download. Without it a box that has google-chrome but
// has never run `puppeteer browsers install` fails at launch with a version
// string and no hint.
export const {
  findChromeExecutable,
  waitForDisplaysDone,
  waitForLoadingComplete,
  waitForQuiescent,
} = await import(fromMonorepo('products/jbrowse-capture/src/index.ts'))

export const REPO = new URL('..', import.meta.url).pathname

const TYPES = {
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.html': 'text/html',
  '.json': 'application/json',
}

/**
 * Serve this repo's files, with one generated page at /harness.html — which
 * takes the bundle to load as `?bundle=`. Port 0: the two scripts can run at
 * once, and neither collides with a dev server.
 */
export async function serveRepo(harness) {
  const server = createServer(async (req, res) => {
    const url = new URL(req.url, 'http://localhost')
    const bundle = url.searchParams.get('bundle')
    if (url.pathname === '/harness.html' && bundle) {
      res.setHeader('content-type', 'text/html')
      res.end(harness(bundle))
      return
    }
    try {
      const body = await readFile(join(REPO, url.pathname))
      // everything not listed is data (.gz, .tbi, .bw, ...), which the adapters
      // fetch by byte range and never sniff
      res.setHeader(
        'content-type',
        TYPES[extname(url.pathname)] ?? 'application/octet-stream',
      )
      res.end(body)
    } catch {
      res.statusCode = 404
      res.end('not found')
    }
  })
  await new Promise(r => {
    server.listen(0, r)
  })
  return {
    port: server.address().port,
    close: () => {
      server.close()
    },
  }
}

/**
 * A page that fakes just enough of the htmlwidgets host to drive one widget,
 * and delivers the bundle the way htmlwidgets does: a plain classic `<script
 * src>` from a directory that holds nothing else.
 *
 * Measured, because it is what the bundle may and may not assume about itself.
 * htmlwidgets declares the binding dependency with `all_files: FALSE`, so a
 * sibling chunk beside the script is never copied into a saved document; and
 * `selfcontained = TRUE` inlines the whole bundle into an inline `<script>`
 * element, where there is no script URL at all. So a bundle that resolves
 * anything relative to itself is broken in a way this delivery is the friendly
 * end of. `bundle.yaml` asserts nothing sits beside the script to be resolved.
 *
 * `extra` is browser-side source spliced in before the bundle loads — a Shiny
 * stub, a recorder. `window.render(x)` drives renderValue, so a re-render (the
 * thing Shiny does on every reactive change) is one more call.
 */
export function htmlwidgetsHost(bundle, { id = 'root', extra = '' } = {}) {
  const css = `${basename(bundle, '.js')}.css`
  return `<!doctype html><html><head><meta charset="utf8">
<link rel="stylesheet" href="/inst/htmlwidgets/${css}">
<style>html,body{margin:0}#${id}{width:1000px}</style>
<script>
window.HTMLWidgets = { widget: d => { window.__widget = d } }
window.__renders = 0
${extra}
</script>
<script src="/inst/htmlwidgets/${bundle}"></script></head><body>
<div id="${id}"></div>
<script>
const el = document.getElementById(${JSON.stringify(id)})
const inst = window.__widget.factory(el, el.clientWidth, 700)
window.render = x => { inst.renderValue(x); window.__renders++ }
window.render(window.__x)
window.__rendered = true
</script></body></html>`
}

const READY_TIMEOUT = 90000

/**
 * Ready when the loading overlay is gone, no "Downloading…"/"Loading…" status
 * text remains, and every display has flipped to its `-done` test-id — the same
 * signals jbrowse-web's own browser tests use, rather than a sleep.
 */
export async function waitForReady(page, timeout = READY_TIMEOUT) {
  await waitForLoadingComplete(page, { waitForDownloads: true, timeout })
  await waitForQuiescent(page, { timeout })
  await waitForDisplaysDone(page, timeout)
}

// Headless renders WebGL through swiftshader, which is what the genome views
// need and all this repo's figures use.
const HEADLESS_ARGS = [
  '--no-sandbox',
  '--enable-unsafe-swiftshader',
  '--use-gl=angle',
  '--use-angle=swiftshader',
  '--ignore-gpu-blocklist',
]

export function launch() {
  return puppeteer.launch({
    headless: true,
    executablePath: findChromeExecutable(),
    args: HEADLESS_ARGS,
  })
}
