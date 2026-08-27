# Handoff

State as of the API-reduction work. Read `IDEAS.md` for deferred features; this
is the "what just changed, what will bite you" file.

## The design rule now in force

**R adds only what JSON cannot express itself.** Everything else is a plain list
handed to JBrowse.

The package exports these names:

| | why it survives |
|---|---|
| `JBrowseR`, `JBrowseRApp` | the widgets |
| `JBrowseROutput`, `renderJBrowseR` | the Shiny bindings |
| `JBrowseRAppOutput`, `renderJBrowseRApp` | the app's, which cannot be shared (htmlwidgets dispatches on the element's class) |
| `track_data_frame` | a data frame is not JSON |
| `update_location` | moving a rendered browser is not config |

`configuration` is not a helper and does not count against that bar: it is
JBrowse's root config block handed straight over, so `formatDetails`, `logoPath`
and `shareURL` all arrived without an R argument each. `theme` survives as the
shorthand for its one slot. Adding an argument that passes a config through is
the shape to reach for; adding one that *shapes* config is not.

`assembly`, `track`, `tracks`, `text_index`, `theme`, `view`, `linear_view`,
`synteny_view`, `dotplot_view`, `synteny_track` and `json_config` were all
deleted: each returned a list literal, and each had to grow whenever JBrowse
gained a type. If you are about to add a helper that shapes config, don't — put
the list in the docs instead. A view type, adapter or display JBrowse adds now
needs **nothing** here.

Deleting `theme()` also stopped the package masking `ggplot2::theme`, which any
Shiny app that plots was hitting.

## Traps

**A length-1 vector becomes a JSON scalar.** This is the one real tax of writing
config as R lists, and the deleted builders were hiding it. Fields JBrowse reads
as arrays need `list()`:

```r
assemblyNames = list("hg38")   # ["hg38"]
assemblyNames = "hg38"         # "hg38"  <- wrong, silently
```

`tests/testthat/test-app.R` pins this. It bites hardest on `assemblyNames`,
`aliases`, and a view spec's `tracks`.

**`input$<id>_location` is printed for reading, not for parsing.** It is
`coarseVisibleLocStrings` verbatim — the location box's own string. So the
coordinates carry thousand separators, a split view gives several regions
space-separated, and a multi-assembly view prefixes `{assemblyName}`. The one
that actually bites: the refName is the *assembly's*, so `JBrowseR("hg38")`
reads back `chr17` even when you asked for `17` and your data frame says `17`.
JBrowse aliases the two, so the track still renders and only a string
comparison in R notices. `example_apps/interactive_peak_calling/app.R` has the
parser (`parse_locstring`/`bare_ref`) worked out; copy it rather than rederive.

**CI builds against upstream `main`; you build against your checkout.** The
`link:` deps point at a sibling `jbrowse-components` working tree, and `tsc`
follows them into its *source* — so `pnpm build` and `pnpm typecheck` passing
here says nothing about CI, which clones `GMOD/jbrowse-components` main
instead. Anything you just added to the monorepo has to be pushed before this
repo's jobs can go green, and the failure names the missing export rather than
the cause. This is not hypothetical: the whole embedded API (`localFiles`,
`getSessionSnapshot`, `setSession`) sat unpushed while both sibling repos'
`bundle`/`typecheck` jobs were red for it. Check `git log origin/main..HEAD` in
the monorepo before concluding a job is broken.

**`resolve.dedupe` makes this repo's version win.** `mobx` is deduped against the
linked monorepo checkout, so the version in `package.json` is not a local
preference — it must track the monorepo's. A monorepo bump breaks `pnpm build`
here and nothing else notices. This is exactly how mobx 6-vs-7 sat broken for
two weeks (`"compareStructural" is not exported`).

**No Node polyfills, on purpose.** The bundle has no `Buffer` and every
`process` read is behind a `typeof process` guard, so `vite-plugin-node-polyfills`
was deleted; only `define: {'process.env.NODE_ENV'}` remains. It cost ~0.5MB per
bundle. Don't reinstate it on a "process is not defined" — check the guard first.
If you add an assertion, note `grep 'Buffer\.'` matches `ArrayBuffer.isView`; use
`grep -E '(^|[^A-Za-z0-9_$])Buffer\.'`.

**esbuild does not typecheck.** `pnpm build` succeeding proves nothing about
types; a missing import ships happily and fails at runtime. That happened in the
sibling anywidget repo this session. Run `pnpm typecheck`.

**`shiny::addResourcePath()` cannot serve indexed files.** It returns the whole
file for a range request — `200`, full `Content-Length`, no `Accept-Ranges`.
JBrowse reads BAM/CRAM/tabix/bigWig by seeking, so every seek pulls the entire
file. It is the obvious thing to reach for and it fails quietly: fine on a small
BED, an apparent hang on an alignment file. `vignettes/creating-urls.Rmd`
documents this; measured, not assumed.

**Figures are timing-dependent.** `tools/screenshot_examples.mjs` produces
byte-different PNGs on re-render even with no code change. Don't commit
regenerated figures in a change that isn't about them; `git checkout man/figures/`
after a verification run.

**Figures come from running the documents that show them.**
`Rscript tools/gen_screenshot_specs.R` executes `vignettes/JBrowseR.Rmd` and
`vignettes/comparative-synteny.Rmd` and keeps the widget each labelled chunk
built; `node tools/screenshot_examples.mjs` renders those. **A chunk's label IS
its figure's name**, so `![...](../man/figures/demo-genes.png)` under a
```{r demo-genes} block is a picture of the code above it. The script used to
restate each config alongside the vignette that showed it, and the two agreed
only while someone kept them agreeing.

Two things fail the run rather than shipping a stale figure: a figure the prose
points at with no chunk to build it (the names are scanned out of `README.Rmd`
and the vignettes, so it is a closed loop), and a labelled chunk whose last
value is not a widget. Executing them is also the only check that the documented
code *runs* — the vignettes set `eval = FALSE`, so knitting never evaluates a
line of it.

The `render` workflow does all this nightly, and by `workflow_dispatch` on
demand — deliberately not on push/PR, because it needs real network and links
against jbrowse-components `main`, so it fails for reasons unrelated to the
commit that triggered it. It fails the run if any example never paints a canvas,
and uploads the figures as an artifact either way.

## The controller takes one declarative `update()`

`LinearGenomeViewController` is `whenReady` / `update(state)` / `destroy`. The
setters this package used to call are gone upstream — `setLocation` last, which
left `tsc --noEmit` red. `update` takes `{ tracks?, location?, localFiles? }`:
each field you state is the complete wanted value, a field you leave out is left
alone, and the engine survives.

**A re-render is no longer a rebuild.** `renderValue` compares the payload
against the last one and, when they differ only in those three fields, states
them instead of destroying the browser. In Shiny that is every reactive read
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

`update_location()` is unchanged as an R function and still worth having: it is
the direction that does not re-run the render expression, so reading
`input$<id>_location` in an `observeEvent()` that calls it is not circular. Its
wire method is now `update`, carrying the state; `setLocation` named a
controller method that no longer exists.

**A build failure needs `onError`.** `createLinearGenomeView` returns
synchronously and resolves the assembly inside itself, so a genome that will not
resolve never reaches the promise `defineWidget` awaits — `defineWidget` hands
`build` a `fail` callback for exactly this. Without it the widget is a blank box
and the reason is console-only. `createApp` is synchronous throughout and needs
none, which is also why `JBrowseRApp()` has no live path: its controller's
`setSession` replaces the whole tree rather than reconciling into it.

**The seam is untyped, so it is pinned from both ends.**
`tests/testthat/test-update.R` has what R sends; `tools/verify_widget.mjs`
drives the built bundle in a real browser and asserts what it does with it.
Nothing type-checks `"jbrowser-call"` or the `{id, method, args}` shape across
the two languages, so a rename on one side is otherwise silent.

That verifier also pins the live reconcile, and pins it with **two** assertions
because neither alone is enough: a rebuild opens the new track too, so "the
track appeared" passes either way. What discriminates is that the container is
never emptied (`root.unmount()` is a rebuild's own signature) and that the view
stays where a prior `update_location()` put it. Note what it does NOT assert:
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
an exported `update_location()` that silently does nothing for anyone who
installs from GitHub. It is built against the *local* monorepo checkout, so
rebuild it once the monorepo commits it needs are pushed.

## The RPC runs on the main thread, and here it has to

The sibling anywidget passes `makeWorkerInstance`, so BAM/CRAM parsing is off
its UI thread. That does not port, and the reason is htmlwidgets' delivery
rather than a preference. Measured, all of it, on 2026-08-27:

- **htmlwidgets delivers one file and nothing beside it.** The binding
  dependency comes back with `all_files: FALSE`
  (`htmlwidgets:::widget_dependencies("JBrowseR", "JBrowseR")`), so a sibling
  chunk is never copied. Dropped a `sibling-probe.js` next to `JBrowseR.js` and
  saved a widget both ways: neither `_files` directory contains it.
- **A self-contained document has no script URL at all.**
  `saveWidget(selfcontained = TRUE)` inlines the whole 4.9MB bundle into an
  *inline* `<script>` element — verified by finding the bundle's first bytes
  inside the 4.8MB HTML, and there is no `<script src>` and no `data:` URI. So
  `document.currentScript.src` is empty and nothing resolves against it.
- **The portable spelling does not even build.**
  `new Worker(new URL('.../rpcWorker', import.meta.url))` fails as
  `[vite:worker-import-meta-url] Invalid value "iife" for option
  "worker.format" - UMD and IIFE output formats are not supported for
  code-splitting builds`. Adding `worker.rollupOptions.output.inlineDynamicImports`
  makes it build, and it then emits
  `new Worker(new URL("/assets/rpcWorker-<hash>.js", <currentScript.src or document.baseURI>))`
  — **root-absolute**, so the base is discarded and it resolves to
  `<origin>/assets/...` under all three delivery modes: Shiny, a loose
  `saveWidget`, and a self-contained document. That is never where the file is,
  and per the first bullet the file is never copied at all.
- **So `?worker&inline` is the only road, and it costs the CRAN budget.**
  Inlining it took `JBrowseR.js` from 4,909 kB to 9,805 kB (gzip 1,505 → 2,987
  kB) — the worker's copy of the adapters is a second copy. The package tarball
  is **6.19 MB today**, and inlining just the *linear-view* worker put it at
  7.60 MB. Doing both bundles is another ~1.7 MB on top. CRAN's guidance is 5 MB.

`bundle.yaml` asserts the consequence rather than the reasoning: each bundle is
one file with nothing beside it, so a vite change that emits a chunk fails there
instead of 404ing in someone's knitted report.

If this is ever worth revisiting, the lever is a worker entry narrower than
`corePlugins` — the same one the anywidget's handoff names.

## Known broken / unresolved

`JBrowseRApp()` has no proxy. Its controller has no location door at all, and
the anywidget's `IDEAS.md` calls view identity the blocker — but that is now
stale on both sides: `ManagedView` already carries an `id`, and `createApp`
defaults one per view (`viewsToSession`), so `setViewLocation(id, loc)` is
well-defined whenever someone wants to add it upstream.

