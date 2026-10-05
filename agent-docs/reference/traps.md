# Traps

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
line of it. `tests/testthat/test-docs.R` is the offline half: it parses every
R chunk and notebook code cell and fails on a function nothing exports, an
argument a JBrowseR function lacks, or a view nesting `init`.

The `render` workflow does all this nightly, and by `workflow_dispatch` on
demand — deliberately not on push/PR, because it needs real network and links
against jbrowse-components `main`, so it fails for reasons unrelated to the
commit that triggered it. It fails the run if any example never paints a canvas,
and uploads the figures as an artifact either way.
