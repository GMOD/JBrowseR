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

**Verify config changes by rendering, not by reading.** The 11 figures in
`tools/screenshot_specs.json` exercise real configs end-to-end, which is what
caught that the raw-list rewrites of the theme, synteny and dotplot specs were
semantically right and not just syntactically. `Rscript tools/gen_screenshot_specs.R`
then `node tools/screenshot_examples.mjs`. The `render` workflow does exactly
this nightly, and by `workflow_dispatch` when you want it on demand — it is
deliberately not on push/PR, because it needs real network and links against
jbrowse-components `main`, so it fails for reasons unrelated to the commit that
triggered it. It fails the run if any example never paints a canvas, and
uploads the figures as an artifact either way.

## Why `update_location` is one function and not a proxy object

`update_location(outputId, loc)` moves a rendered browser without rebuilding
it. It is one exported name and one custom message — deliberately not the
leaflet-style `proxy <- jbrowse_proxy(id)` object, which exists there to
accumulate many calls and flush them, and here would only be a second exported
name and a class to document in front of a single command. Before it, a Shiny app navigated by putting a
reactive into `renderJBrowseR()`, which destroys and rebuilds the browser —
refetching its tracks and discarding zoom, track order and selection. Four of
the bundled example apps did exactly that.

The controller also offers `setTracks`, `setAssembly`, `setSession`,
`addTrack`, `removeTrack` and `addLocalFiles`, and none of them are wired.
That is the decision recorded in `IDEAS.md`, unchanged: each has to answer what
it does to a track the user opened by hand or a layout they rearranged, and
"rebuild" is a defensible answer to those — which is what re-rendering the
widget already does. Navigation has one meaning and is the interaction that
repeats. If you wire another, wire it in the anywidget first; that repo has no
CRAN cycle and exercises the semantics against real notebook use.

**The seam is untyped, so it is pinned from both ends.**
`tests/testthat/test-proxy.R` has what R sends; `tools/verify_proxy.mjs` drives
the built bundle in a real browser and asserts what it does with it. Nothing
type-checks `"jbrowser-call"` or the `{id, method, args}` shape across the two
languages, so a rename on one side is otherwise silent. The verifier rides the
nightly `render` workflow, which already has the browser, the built bundle and
the network it needs.

One thing that verifier exists to hold: **a proxy call can arrive mid-build**.
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

## Known broken / unresolved

`JBrowseRApp()` has no proxy. Its controller has no `setLocation` at all, and
the anywidget's `IDEAS.md` calls view identity the blocker — but that is now
stale on both sides: `ManagedView` already carries an `id`, and `createApp`
defaults one per view (`viewsToSession`), so `setViewLocation(id, loc)` is
well-defined whenever someone wants to add it upstream.

