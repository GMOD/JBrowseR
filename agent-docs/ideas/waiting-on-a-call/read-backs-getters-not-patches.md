---
name: read-backs-getters-not-patches
description: Mirror declared observable reads into host state with one mechanism instead of a callback per fact; never build read-backs on onChange patches.
---

# Read-backs: getters, not patches

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
