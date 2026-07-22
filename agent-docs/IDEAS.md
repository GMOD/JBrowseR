# Ideas

Deferred work worth revisiting. Not a roadmap — things we decided not to do yet,
with enough context to pick up cold.

## Reactivity: updating a browser without rebuilding it

Today every change rebuilds. `renderValue` in `srcjs/widget.ts` destroys the
previous controller and calls `create*` again, so in Shiny any reactive input
feeding `renderJBrowseR()` throws away the user's zoom, track order, scroll
position, and feature selection. The only signal out is `onFeatureSelect`.

The controller can do better. `createLinearGenomeView` returns `setAssembly`,
`setTracks`, `setSession`, `setLocation`, and accepts `onLocationChange`. The
sibling anywidget (`~/src/jbrowse-anywidget`, `src/index.ts`) drives all of them
from traitlets, so the mechanism is proven — the question is what belongs in R.

The R-side shape would be htmlwidgets proxies, not anything anywidget-like:
`jbrowse_proxy(outputId)` plus `session$sendCustomMessage`, dispatched in
`widget.ts` to the live controller. Standard for the ecosystem (leaflet, plotly),
and CRAN-safe.

### Why we stopped at one bug fix

The components aren't declarative. `init` is a `defaultValue`: it seeds a MobX
session that the user then mutates by panning and dragging. Mirroring that into
declarative R state means reconciliation, and the reconciliation is where the
semantics get murky — what should `update_tracks()` do to a track the user
opened by hand, or to a view layout they rearranged? "Rebuild" is a defensible
answer to those, not merely a limitation.

The cost is visible in the anywidget already: `onLocationChange` has to guard
`if (model.get('location') !== locs)` before writing back, because a trait
mirroring an uncontrolled view echoes. Each additional two-way trait buys another
instance of that.

### If we pick this up

`update_location()` is the one that resolves cleanly — navigation is the repeated
interaction, a full rebuild to move the locus is visibly wasteful, and location
has one unambiguous meaning that `setLocation` already handles as a plain async
call. Do that alone before anything else.

`setTracks` / `setAssembly` / `setSession` should earn it in the anywidget first.
That repo has no CRAN cycle and one maintainer, and it exercises them against
real notebook use. If they hold up there — no echo weirdness, no surprising loss
of view state — port them with the semantics already settled.

An alternative worth weighing: make the components genuinely declarative
upstream, in `@jbrowse/react-linear-genome-view2`, instead of growing imperative
handles in each embedding. That is a much larger change and would want its own
design, but it is the version where R, Python, and plain React all get the same
answer.

## Feature selection from JBrowseRApp

`JBrowseR()` reports clicks via `onFeatureSelect`; `JBrowseRApp()` reports
nothing, because `createApp` in `@jbrowse/react-app2` exposes no such option.
The anywidget gets at it by autorunning on the session directly (see
`src/app.ts`), which the htmlwidget can't do without reaching past the
controller API.

The clean fix is upstream: give `createApp` the same `onFeatureSelect` /
`onLocationChange` options `createLinearGenomeView` has. Then both embeddings
stop being special cases.

## Shared JS between JBrowseR and jbrowse-anywidget

`srcjs/` and `~/src/jbrowse-anywidget/src/` have converged: `stream-web-shim.ts`
is byte-identical, and the two `vite.config.js` files differ only in output
format (IIFE vs ESM) and comment wording. The entries genuinely differ — one
talks to `renderValue`, the other to a traitlet model — so there is less to share
than it looks.

Not worth a shared npm package at this size. What is actually at risk is the
hard-won shim knowledge in the vite config (the `stream/web` interception, the
react/mobx dedupe for linked monorepo packages); if that drifts and only one copy
gets the fix, the other breaks in a way that is annoying to rediscover. Revisit
if a third embedding appears, or if the configs drift in substance rather than
prose.
