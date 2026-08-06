# Ideas

Deferred work worth revisiting. Not a roadmap — things we decided not to do yet,
with enough context to pick up cold.

## Reactivity: updating a browser without rebuilding it

**Partly done.** `update_location()` shipped in 0.12.0 and
navigation no longer rebuilds; see HANDOFF.md. What follows is the reasoning
for the rest, which is unchanged and still deliberately not built.

Today every other change rebuilds. `renderValue` in `srcjs/widget.ts` destroys the
previous controller and calls `create*` again, so in Shiny any reactive input
feeding `renderJBrowseR()` throws away the user's zoom, track order, scroll
position, and feature selection. The only signal out is `onFeatureSelect`.

The controller can do better. `createLinearGenomeView` returns `setAssembly`,
`setTracks`, `setSession`, `setLocation`, and accepts `onLocationChange`. The
sibling anywidget (`~/src/jbrowse-anywidget`, `src/index.ts`) drives all of them
from traitlets, so the mechanism is proven — the question is what belongs in R.

The R-side shape is `session$sendCustomMessage`, dispatched in `widget.ts` to
the live controller — the mechanism leaflet's and plotly's proxies use
underneath, without the proxy object, which buys nothing until there are enough
commands to want to batch them.

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
call. Done: it is one custom message rather than an htmlwidgets proxy object per
call, which is the same mechanism leaflet's proxies use underneath.

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

**Done in 0.12.0.** `createApp` grew `SessionObservers` (`onFeatureSelect`,
`onLocationChange`, `onSessionChange`), so the app widget now reports
`_selected_feature` and `_location` like the single-view one. What follows was
the state before that landed, kept for the reasoning about reaching past the
controller.

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

## Read-backs: getters, not patches

Colin, 2026-08-06, on where the value in a host API is: "the true value is in
the full api surface of getters and stuff with observable", and "if a lot of
effort is being dedicated to onpatch that is probably bad".

Nothing here uses `onPatch`, and the read-backs this package rides are not
patch-based: `observeSession` in product-core is two MobX autoruns over a
deliberately coarse derived signal (per view: `id`, location, open trackIds),
which is what makes `_location`/`_session`/`_selected_feature` settle after a
gesture rather than firing per pointer event. That part is already the right
shape.

The thing the note is about lives upstream: `createViewState`'s
`onChange?: (patch, reversePatch)` in both React products, wired straight to
MST's `onPatch`. It streams raw JSON patches whose paths are the tree's internal
shape, and the only documented example of it
(`products/jbrowse-react-app/examples-site/src/docs/with-on-change.md`) ignores
the patch and calls `getSnapshot(state.session)` in the handler — the API's own
worked example does not use the API. Don't build a host read-back on it.

Where this would go if picked up: one mechanism that mirrors *declared*
observable reads into host state, instead of a callback per fact. The host names
what it wants to watch; the JS side autoruns each and pushes the value. That
generalizes `_location` and `_selected_feature` (each is one getter today) and
reaches the rest of the model surface without a new option per thing. The open
questions are how a host names a getter across the boundary, and what happens to
a name whose model moved — the same versioning problem the session spec has.
