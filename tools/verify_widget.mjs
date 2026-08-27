// End-to-end check of the seams between R and the built bundle, in a real
// browser. Three of them, none reachable from testthat or tsc:
//
//   - the `update_location()` wire. `tests/testthat/test-update.R` pins what R
//     sends; this pins what the bundle does with it. The seam is a string
//     ("jbrowser-call") and a plain object, so nothing typed crosses it and a
//     rename on one side is silent on the other.
//   - the live reconcile. A re-render that changes only `tracks` must reach the
//     browser already on the page rather than build another, which is the whole
//     point of it and is invisible to a build that merely succeeds.
//   - `onError`. createLinearGenomeView resolves the assembly inside itself, so
//     a genome that will not resolve never reaches the promise the widget
//     awaits — the failure has to be routed out or the user gets a blank box.
//
// Needs network — it loads the hosted hg38 hub, same as the figures do.
//
// puppeteer resolves from the sibling jbrowse-components checkout (override
// with PUPPETEER_FROM=/path/to/pkg-dir). Run:  node tools/verify_widget.mjs
import {
  htmlwidgetsHost,
  launch,
  serveRepo,
  waitForReady,
} from './browser_harness.mjs'

// The widget renders into an element whose id is what a Shiny outputId becomes,
// so the proxy call has something to name.
const OUTPUT_ID = 'browserOutput'
const START = '10:29,838,737..29,838,819'
const TARGET = '17:43,044,295..43,125,483'

// Features held in the config itself, so opening this track is not a second
// network fetch — the reconcile is what is under test, not an adapter.
const LATE_TRACK = {
  type: 'FeatureTrack',
  trackId: 'reconciled_track',
  name: 'ReconciledLateTrack',
  adapter: {
    type: 'FromConfigAdapter',
    features: [
      {
        refName: '17',
        start: 43045000,
        end: 43060000,
        name: 'late',
        uniqueId: 'late-1',
        type: '',
      },
    ],
  },
}

// A Shiny stub that records setInputValue calls and keeps the custom message
// handler the bundle registers, so both directions are observable from the
// page; plus a count of the times the widget's container was emptied, which is
// what `root.unmount()` does and so is a rebuild's own signature.
//
// Deliberately NOT a DOM identity check: React legitimately replaces the
// header's nodes when the track list changes, so "the nodes changed" reads as a
// rebuild that never happened.
const RECORDERS = `
window.__inputs = {}
window.__handlers = {}
window.__unmounts = 0
window.Shiny = {
  setInputValue: (id, value) => { window.__inputs[id] = value },
  addCustomMessageHandler: (type, handler) => { window.__handlers[type] = handler },
}
document.addEventListener('DOMContentLoaded', () => {
  const el = document.getElementById(${JSON.stringify(OUTPUT_ID)})
  new MutationObserver(() => {
    if (el.childElementCount === 0) { window.__unmounts++ }
  }).observe(el, { childList: true })
})
`

const { port, close } = await serveRepo(bundle =>
  htmlwidgetsHost(bundle, { id: OUTPUT_ID, extra: RECORDERS }),
)
const browser = await launch()

const failures = []
function check(ok, what) {
  console.log(`${ok ? '✓' : '✗'} ${what}`)
  if (!ok) {
    failures.push(what)
  }
}

async function open(x) {
  const page = await browser.newPage()
  const errors = []
  page.on('pageerror', e => {
    errors.push(String(e))
  })
  await page.setViewport({ width: 1000, height: 440 })
  await page.evaluateOnNewDocument(payload => {
    window.__x = payload
  }, x)
  await page.goto(`http://localhost:${port}/harness.html?bundle=JBrowseR.js`, {
    waitUntil: 'load',
    timeout: 60000,
  })
  await page.waitForFunction(() => window.__rendered === true, { timeout: 30000 })
  return { page, errors }
}

const errors = []

// ---- the proxy wire, and the live reconcile on top of where it left the view
{
  const { page, errors: pageErrors } = await open({
    assembly: 'hg38',
    location: START,
  })
  errors.push(...pageErrors)
  try {
    const registered = await page.evaluate(
      () => typeof window.__handlers['jbrowser-call'] === 'function',
    )
    check(registered, 'the bundle registers a jbrowser-call handler')

    // Sent immediately after renderValue, while createLinearGenomeView is still
    // resolving. This is the race an `observe()` at app startup hits, and the
    // reason the registry holds the build promise: a caller keyed to the
    // resolved controller would drop this call with the browser looking fine.
    await page.evaluate(
      (id, location) => {
        window.__handlers['jbrowser-call']({
          id,
          method: 'update',
          args: { location },
        })
      },
      OUTPUT_ID,
      TARGET,
    )

    // The location read-back is the assertion: the view reports where it ended
    // up through the same onLocationChange the Shiny input rides, so this
    // proves the navigation happened rather than that the call was accepted.
    //
    // It comes back as `chr17:…` though `17:…` was sent, because the reported
    // refName is the assembly's and the hub's hg38 spells it `chr17`. JBrowse
    // aliases the two, so this is what a Shiny app comparing strings sees too —
    // the trap the HANDOFF's `_location` note is about, asserted here rather
    // than only described.
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
    check(landed, `a mid-build update lands (reported "${reported}")`)

    // Now the thing Shiny does on every reactive change: render again. The
    // payload's `location` is still START, so a rebuild would yank the view
    // back to chromosome 10 and empty the container on the way. Reconciling
    // leaves the user where the proxy call put them and only opens the track.
    await waitForReady(page)
    const before = await page.evaluate(() => window.__unmounts)
    await page.evaluate(
      (location, track) => {
        window.render({ assembly: 'hg38', location, tracks: [track] })
      },
      START,
      LATE_TRACK,
    )
    const opened = await page
      .waitForFunction(
        name => document.body.innerText.includes(name),
        { timeout: 60000 },
        LATE_TRACK.name,
      )
      .then(() => true)
      .catch(() => false)
    check(opened, 'a re-render that adds a track opens it')

    await waitForReady(page)
    const after = await page.evaluate(
      id => ({
        unmounts: window.__unmounts,
        location: window.__inputs[`${id}_location`],
      }),
      OUTPUT_ID,
    )
    check(
      after.unmounts === before,
      `the container is not emptied by that re-render (${after.unmounts - before} unmounts)`,
    )
    check(
      /^(chr)?17:/.test(after.location ?? ''),
      `and the view stays where the user left it (reported "${after.location}")`,
    )

    // An id that names no rendered widget must not throw: a Shiny handler that
    // throws is not obviously fatal, but it leaves the page's message channel
    // in a state nothing else on the page can diagnose.
    const unknownIdThrew = await page.evaluate(() => {
      try {
        window.__handlers['jbrowser-call']({
          id: 'not-a-widget',
          method: 'update',
          args: { location: '1:1-100' },
        })
        return false
      } catch {
        return true
      }
    })
    check(!unknownIdThrew, 'a call naming no rendered widget is ignored, not thrown')

    const global = await page.evaluate(
      () => 'selectedFeature' in window.__inputs,
    )
    check(!global, 'no global selectedFeature input is set')
  } finally {
    await page.close()
  }
}

// ---- a build failure reaches the widget rather than only the console
{
  // A hub name nothing answers for — the typo'd genome, which is the realistic
  // way this fails. resolveAssembly fetches the hub and throws, inside the
  // build() that createLinearGenomeView never hands back. An assembly *config*
  // with a bad uri would not do: that resolves fine and fails later, in the
  // view's own loading, where the view reports it itself.
  const { page } = await open({
    assembly: 'no-such-genome-xyzzy',
    location: START,
  })
  try {
    const shown = await page
      .waitForFunction(() => !!document.querySelector('.jbrowser-error'), {
        timeout: 60000,
      })
      .then(() => true)
      .catch(() => false)
    check(shown, 'a genome that will not resolve reports into the widget')
  } finally {
    await page.close()
  }
}

await browser.close()
close()

if (errors.length) {
  console.error('page errors:', errors.slice(0, 5).join(' | '))
}
if (failures.length) {
  console.error(`\n${failures.length} check(s) failed`)
  process.exit(1)
}
console.log('\nwidget seams verified')
