# JBrowseR 0.11.0

- Removed `serve_data()` and its hand-rolled HTTP server. Serve local files with
  any static server that supports CORS and range requests (e.g.
  `npx http-server --cors`); see the "Hosting data" vignette. This drops the
  `httpuv`, `mime`, `cli`, and `stringr` dependencies, leaving `htmlwidgets` as
  the package's only import.
- New `JBrowseRApp()` renders the full JBrowse 2 app — any number of views of any
  type — from a declarative `views` list. Each entry is a `list(type, init)`
  spec built with `linear_view()`, `synteny_view()`, or `dotplot_view()`, the
  same vocabulary JBrowse Web serializes into its `?session=spec-…` URLs, so
  comparative genomics (linear synteny, dotplots) is now reachable from R.
  `synteny_track()` builds the PAF track config. It loads a separate widget
  bundle, so the single-view `JBrowseR()` stays lean.
- `assembly()` accepts a `.2bit` URL (`TwoBitAdapter`) in addition to FASTA.

- Upgraded to the GPU-accelerated JBrowse 2 v4 linear genome view
  (`@jbrowse/react-linear-genome-view2`), driven through the shared
  framework-agnostic `@jbrowse/embedded-linear-genome-view` controller.
- New declarative API. `JBrowseR("hg38", location = "BRCA1")` loads a whole
  hosted genome (assembly, reference-name aliases, cytobands, gene search) in one
  line. Build custom browsers from plain values with `assembly()`, `track()`
  (track type and index files inferred from the URL), `tracks()`, `text_index()`,
  and `theme()`, which now return lists rather than JSON strings.
- `tracks` entries also accept a bare data-URL string or a `c(url, index)` pair,
  not just a `track()` config, so a whole browser can skip the constructor.
- Track-type/adapter inference is delegated to JBrowse core: `track()` now
  returns a loose `list(uri = ...)` spec that the view expands at display time
  with the same format plugins the "Add track" flow uses. So any format a bundled
  plugin recognizes works (`.bam`/`.cram`, `.vcf`, `.gff`/`.gff3`/`.gtf`/`.bed`
  plain or bgzipped, `.bb`/`.bigWig`, `.hic`, …) — not a fixed R-side list — and
  a bgzipped file resolves to its indexed tabix adapter, a plain one to the
  whole-file adapter. `track()` no longer takes `type`/`adapter_type`; pass
  overrides as extra `...` arguments, or a full config list for a specific
  adapter.
- `track(url, index = ...)` names a non-sibling index (a `.csi` index is
  detected by extension).
- `assembly` also accepts a bare sequence-file URL (`".../genome.fa.gz"`, or a
  `.2bit`); the view builds the assembly from it, deriving the name from the
  file, so `assembly()` is only needed for reference-name aliases or a
  non-sibling index.
- The old string-building helpers (`track_alignments()`, `track_variant()`,
  `track_wiggle()`, `track_feature()`, `default_session()`) and the `view=`
  first argument (`"View"`/`"JsonView"`/`"ViewHg19"`/`"ViewHg38"`) are removed.
  Pass a hub name or `assembly()` config directly; use `config =` for a full
  JBrowse config.
- Build switched to Vite + pnpm; reactR is no longer a dependency.

# JBrowseR 0.10.2

- Updated to @jbrowse/react-linear-genome-view@2.10.0
- Adds support for lzma cram

# JBrowseR 0.10.1

- Updated to @jbrowse/react-linear-genome-view@2.6.2
- Updated webpack build and dev dependencies

# JBrowseR 0.10.0

- Updated to @jbrowse/react-linear-genome-view@2.5.0
- Updated to webpack 5
- Fixed issue clicking features when running outside of Shiny

# JBrowse 0.9.1

- Updated to @jbrowse/react-linear-genome-view@2.0.1
- Added a new function `text_index()` to provide support for text search.

# JBrowseR 0.9.0

- Updated to @jbrowse/react-linear-genome-view@1.4.4
- Fixed the code example for `track_wiggle()`.
- Updated the URL for the hg38 to fix the CORS error from the old source.

# JBrowseR 0.8.1

This release consists of updates to the JS side of the package:

- Updated to @jbrowse/react-linear-genome-view@1.3.2. This includes:
  - new SVG export feature! 📸
  - a fix for better supporting Dialog components in the UI 🔨
  - performance improvements 🚀
  - better theming support (you can now change the colors of the bases!) 🎨
- Updates the internal React components in the package based on new API changes
  to the React LGV

There are no changes to the R interface.

# JBrowseR 0.8.0

- Added the `track_data_frame()` track type. This makes it possible to create
  JB2 tracks directly from R data frames without any files.
- Updated all views to now send Shiny messages to `input$selectedFeature`
  recorded what feature was clicked on. Check out the new example app
  `bookmark_app.R` for a demo!

# JBrowseR 0.7.1

- Updated URLS in Description to reflect new home in GMOD Github organization.
- Updated to @jbrowse/react-linear-genome-view@1.0.4 (fixes issues with Safari
  and iOS compatibility).

# JBrowseR 0.7.0

- Initial package release!
