# Ideas

Deferred work worth revisiting. Not a roadmap — things we decided not to do yet,
with enough context to pick up cold.

## Reactivity: updating a browser without rebuilding it

**Done**, and by the route the last note called "a much larger change": the
components became declarative upstream rather than each embedding growing
imperative handles. `LinearGenomeViewController` is `whenReady` / `update(state)`
/ `destroy`, `update` takes the whole wanted state, and it reconciles — so R,
Python and plain JS get the same answer. See HANDOFF.md for what that means
here.

Kept because the reasoning was the blocker and is worth not re-deriving: the
question that stopped this was "what should an update do to a track the user
opened by hand, or a view layout they rearranged?", and `reconcileTracks` in
`packages/product-core` answers it — the host's list is the complete wanted set
of *its* tracks, opened if absent and closed if dropped, and the session's own
`getTrackById` keeps a config the user already has from being shadowed. The
echo problem the anywidget hit (`onLocationChange` writing back into the trait
it mirrors) does not arise in htmlwidgets, because R holds no two-way binding:
the payload flows one way and `input$<id>_location` is a read-back nothing feeds
back automatically.

What is still not built is a *narrower* door than a re-render — an
`update_tracks()` to sit beside `update_location()`. Nothing needs it yet:
re-rendering already reconciles, and the one thing `update_location()` buys over
it is not re-running the render expression, which matters for navigation because
it repeats and would otherwise loop through `input$<id>_location`. A track list
changes on a click, not on a drag. The wire already carries the whole state, so
if it is ever wanted it is a line on each side.

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
