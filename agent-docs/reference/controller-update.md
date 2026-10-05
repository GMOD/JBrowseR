# The controller takes one declarative `update()`

`LinearGenomeViewController` is `whenReady` / `update(state)` / `destroy`. The
setters this package used to call are gone upstream — `setLocation` last, which
left `tsc --noEmit` red. `update` takes `{ tracks?, location?, localFiles? }`:
each field you state is the complete wanted value, a field you leave out is left
alone, and the engine survives.

**A re-render is no longer a rebuild.** Each widget defines one `live()` in
`srcjs/`, handed the changed option keys: JBrowseR states them through
`update` when every key is `tracks`, `location` or `localFiles`; JBrowseRApp
calls `setSession` when the only key is `session`; anything else answers false
and the widget rebuilds. A `jbrowser-update` message from `update_jbrowse()`
goes through the same `live()`, and on false rebuilds from the rendered options
plus the changes. A live-applied message leaves the rendered options alone, so
a later re-render that does not restate that key keeps what the message set. In Shiny that is every reactive read
feeding the widget, so a track checkbox opens a track in place rather than
refetching the lot and resetting the user's zoom.

Three things about how, each of which is a way to get it wrong:

- **The comparison is on everything OUTSIDE the three live fields.** A payload
  field JBrowse gains lands on the rebuild side without anyone updating a list.
  That direction is deliberate: a wrong answer costs the rebuild this used to do
  unconditionally, where a field wrongly called live would be silently dropped.
- **The comparison is key-order sensitive** (`JSON.stringify`), because the
  payload is R's own JSON and two renders of one expression order their lists
  the same way. A false "changed" costs a rebuild; a false "unchanged" would
  leave a stale browser looking correct.
- **`localFiles` is live only while it grows.** Upstream keeps the blob a
  registered name already minted, because live track configs point at it. So a
  payload that changes or drops the bytes behind a name it already sent
  rebuilds — otherwise editing a file on disk and re-rendering would silently
  show the old bytes.

`update_jbrowse()` is worth having beside re-rendering because it does not
re-run the render expression, so reading `input$<id>_location` in an
`observeEvent()` that calls it is not circular.

**A build failure needs `onError`.** `createLinearGenomeView` returns
synchronously and resolves the assembly inside itself, so a genome that will not
resolve never reaches the promise `defineWidget` awaits — `defineWidget` hands
`build` a `fail` callback for exactly this. Without it the widget is a blank box
and the reason is console-only. `createApp` is async and rejects its own promise,
so it needs none.

**The seam is untyped, so it is pinned from both ends.**
`tests/testthat/test-update.R` has what R sends; `tools/verify_widget.mjs`
drives the built bundle in a real browser and asserts what it does with it.
Nothing type-checks `"jbrowser-update"` or the `{id, options}` shape across
the two languages, so a rename on one side is otherwise silent.

That verifier also pins the live reconcile, and pins it with **two** assertions
because neither alone is enough: a rebuild opens the new track too, so "the
track appeared" passes either way. What discriminates is that the container is
never emptied (`root.unmount()` is a rebuild's own signature) and that the view
stays where a prior `update_jbrowse()` put it. Note what it does NOT assert:
DOM node identity. React legitimately replaces the header's nodes when the track
list changes, so an identity check reads as a rebuild that never happened.

One thing the verifier exists to hold: **a proxy call can arrive mid-build**.
`build` is async, so an `observe()` firing at app startup races the first
render. The registry in `widget.ts` therefore stores the build *promise*, not
the resolved controller — keyed to the controller, that call would be dropped
with the browser looking perfectly fine.

**The bundle in `inst/htmlwidgets/` is committed with this**, because nothing
else ever rebuilds it (`bundle.yaml`'s header says why: CRAN and
`remotes::install_github` have no JS toolchain). Committing R alone would ship
an exported `update_jbrowse()` that silently does nothing for anyone who
installs from GitHub. It is built against the *local* monorepo checkout, so
rebuild it once the monorepo commits it needs are pushed.

**A stale bundle renders a partial encoding and says nothing.** The bundles
built on 2026-09-16 drew a `LinearMarkDisplay` threshold scale as a viridis
ramp, no reference rules and no axis title, because those landed in the
monorepo on the 20th and 21st; every readiness signal was green. `pnpm build`
first when a figure ignores part of its config.

**Install with `R CMD INSTALL --no-multiarch --no-docs .`, not
`devtools::install()`.** The latter copies the checkout to /tmp before
applying `.Rbuildignore`, and `node_modules` links into the monorepo, so the
copy is the monorepo's dependency tree and dies on space. `library(JBrowseR)`
in `tools/gen_screenshot_specs.R` and `testthat::test_local()` load the
*installed* package, so a figure run before the install reports the old
package's errors.
