# Handoff

State as of the API-reduction work. Read `IDEAS.md` for deferred features; this
is the "what just changed, what will bite you" file.

## The design rule now in force

**R adds only what JSON cannot express itself.** Everything else is a plain list
handed to JBrowse.

The package exports five names:

| | why it survives |
|---|---|
| `JBrowseR`, `JBrowseRApp` | the widgets |
| `JBrowseROutput`, `renderJBrowseR` | the Shiny bindings |
| `track_data_frame` | a data frame is not JSON |

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
semantically right and not just syntactically. `Rscript -e 'source("tools/gen_screenshot_specs.R")'`
then `node tools/screenshot_examples.mjs`.

## Known broken / unresolved

- **No browser render job in CI.** `.github/workflows/bundle.yaml` builds and
  typechecks; nothing renders. `tools/screenshot_examples.mjs` is what proves a
  config change is semantically right, but it needs real network and puppeteer
  resolved from the sibling checkout, so it is the flaky one. Nightly-only would
  suit it.

