# JBrowseR 0.11.0

- Upgraded to the GPU-accelerated JBrowse 2 v5 linear genome view
  (`@jbrowse/react-linear-genome-view2`), driven through the shared
  framework-agnostic `@jbrowse/embedded-linear-genome-view` controller.
- New declarative API. `JBrowseR("hg38", location = "BRCA1")` loads a whole
  hosted genome — assembly, reference-name aliases, cytobands, gene search — in
  one line.
- The config builders are gone, and nothing replaces them: a JBrowse config is
  an R list already. `assembly()`, `track()`, `tracks()`, `text_index()`,
  `theme()`, `json_config()`, `view()`, `linear_view()`, `synteny_view()`,
  `dotplot_view()` and `synteny_track()` each returned a list literal, and each
  had to grow whenever JBrowse gained a type. Write the list the
  [config guide](https://jbrowse.org/jb2/docs/config_guide/) documents instead —
  a view type, adapter or display JBrowse adds now needs no new R function. One
  trap the builders had been hiding: a length-1 vector serializes to a JSON
  scalar, so fields JBrowse reads as arrays need `list()` —
  `assemblyNames = list("hg38")`, not `"hg38"`.
- Dropping `theme()` also stops the package masking `ggplot2::theme()`, which
  any Shiny app that plots was hitting.
- New `JBrowseRApp()` renders the full JBrowse 2 app — any number of views of
  any type — from a `views` list of `list(type = , init = )` specs, the same
  vocabulary JBrowse Web serializes into its `?session=spec-…` URLs, so
  comparative genomics (linear synteny, dotplots) is reachable from R. It loads
  a separate widget bundle, so the single-view `JBrowseR()` stays lean.
- `JBrowseRApp()` gained Shiny bindings — `JBrowseRAppOutput()` and
  `renderJBrowseRApp()` — so the multi-view app is usable in a Shiny app at all.
  It could not share `JBrowseROutput()`: htmlwidgets dispatches on the output
  element's class, so the app rendered into one loaded the single-view bundle
  and failed to build.
- A layout saves and reopens. `JBrowseRApp()` takes `session = `, and a running
  app reports whatever the user built — navigation, open tracks, added or
  rearranged views — as `input[[paste0(outputId, "_session")]]` in that same
  shape. So "save this layout" is storing that value and reopening it is handing
  it back; a restored session takes precedence over `views`, which still
  describes what File → New session returns to. The read-back rides a coarse
  signal (which views exist, what each has open, where each is looking), so it
  settles after a gesture instead of pushing a snapshot per frame. See the
  `save_session` example app.
- Panning or zooming now sets `input[[paste0(outputId, "_location")]]` to the
  visible region, so a Shiny server can recompute for what the user is looking
  at — the selected feature was previously the only signal out. It settles
  after the gesture rather than firing per frame. See the interactive peak
  calling example app.
- Clicking a feature now also sets `input[[paste0(outputId,
  "_selected_feature")]]`, namespaced per output, so several browsers on one page
  no longer overwrite each other's selection and the value is reachable from
  inside a Shiny module. The global `input$selectedFeature` still fires.
- A browser that fails to load now reports the error in place instead of
  rendering a blank widget with the reason only in the devtools console.
- `track_data_frame()` survives the cull, because a data frame is the one thing
  config JSON cannot express. It carries every column beyond
  `chrom`/`start`/`end`/`name` onto each feature (previously only `score` and
  `additional`), so any column you computed shows in the feature details.
- `tracks` entries accept a bare data-file URL or a `list(uri = , index = )`
  spec as well as a full config. Track type, adapter and index sibling are
  inferred by JBrowse core at display time, using the same format plugins the
  "Add track" flow uses, so any format a bundled plugin recognizes works
  (`.bam`/`.cram`, `.vcf`, `.gff`/`.gff3`/`.gtf`/`.bed` plain or bgzipped,
  `.bb`/`.bigWig`, `.hic`, …) rather than a fixed R-side list. Entries missing
  `assemblyNames` are backfilled with the assembly's name by the view.
- `assembly` also accepts a bare sequence-file URL (`".../genome.fa.gz"`, or a
  `.2bit`); the view builds the assembly from it, deriving the name from the
  file.
- `config =` takes the path, URL or JSON text of a `config.json` directly, as
  well as a list, so reading the file is no longer a separate step.
- Removed `serve_data()` and its hand-rolled HTTP server. Serve local files with
  any static server that supports CORS and range requests (e.g.
  `npx http-server --cors`); see the "Hosting data" vignette. This drops the
  `httpuv`, `mime`, `cli`, and `stringr` dependencies, leaving `htmlwidgets` as
  the package's only import.
- The old string-building helpers (`track_alignments()`, `track_variant()`,
  `track_wiggle()`, `track_feature()`, `default_session()`) and the `view=`
  first argument (`"View"`/`"JsonView"`/`"ViewHg19"`/`"ViewHg38"`) are removed.

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
