# JBrowseR 0.14.0

Install with `devtools::install_github("GMOD/JBrowseR")`.

- `track_data_frame()` no longer needs a `name` column, takes the reference name
  as `chrom`, `chr` or `refName`, and builds its features column-wise rather
  than slicing the frame a row at a time.
- A `displays` entry handed to `track_data_frame()` plots the columns:
  `LinearMarkDisplay` is JBrowse's grammar of graphics, and the introduction
  vignette draws a windowed Fst scan as bars on a value axis coloured by a
  threshold scale.
- The widget bundles are rebuilt, bringing the mark display's threshold scales,
  reference rules and axis titles.

# JBrowseR 0.13.0

Install with `devtools::install_github("GMOD/JBrowseR")`.

- **Breaking:** `JBrowseR()` and `JBrowseRApp()` take JBrowse's own options as
  named arguments and pass them through unread: `createLinearGenomeView`'s for
  `JBrowseR()` (`assembly`, `tracks`, `location`, `session`,
  `aggregateTextSearchAdapters`, `internetAccounts`, `plugins`,
  `configuration`) and `createApp`'s for `JBrowseRApp()` (`assemblies`,
  `tracks`, `views`, `session`, `connections`, ...). The signatures are
  `JBrowseR(..., local_files = NULL, width = NULL, height = NULL, elementId = NULL)`
  and the same for `JBrowseRApp()`, so an option JBrowse adds works with no
  package update. Every option is named; the genome is no longer positional.

  ```r
  # before
  JBrowseR("hg38", location = "BRCA1")
  # after
  JBrowseR(assembly = "hg38", location = "BRCA1")
  ```

- **Breaking:** `theme =` and `text_search =` are gone. Both were renamings of
  a JBrowse option.

  ```r
  # before
  JBrowseR(assembly = hg19, text_search = search, theme = palette)
  # after
  JBrowseR(
    assembly = hg19,
    aggregateTextSearchAdapters = list(search),
    configuration = list(theme = palette)
  )
  ```

- **Breaking:** `config =` is gone. A JSON file of options is a `do.call()`:

  ```r
  # before
  JBrowseR(config = "config.json", location = "BRCA1")
  # after
  do.call(JBrowseR, jsonlite::read_json("config.json"))
  do.call(JBrowseR, modifyList(jsonlite::read_json("config.json"), list(location = "BRCA1")))
  ```

- **Breaking:** `update_location()` is now `update_jbrowse()`, which sends any
  subset of the options to a rendered browser and works on `JBrowseRApp()` too.
  `JBrowseR()` applies `tracks` and `location` in place and `JBrowseRApp()`
  applies `session` in place; any other option rebuilds from the rendered
  options plus the change.

  ```r
  # before
  update_location("browser", "BRCA1")
  # after
  update_jbrowse("browser", location = "BRCA1")
  update_jbrowse("app", session = saved)
  ```

- `jsonlite` moves from Imports to Suggests: the package no longer reads JSON
  itself.

- A `JBrowseRApp()` view is `list(type = , ...)` with its settings beside
  `type`, the same object a `config.json`'s `defaultSession.views` holds.

- Re-rendering a browser no longer throws it away. A render whose payload
  differs only in `tracks`, `location` or `local_files` is reconciled into the
  browser already on the page — the tracks it names open, the ones it drops
  close — and the user's zoom, track order, scroll position and feature
  selection survive. In Shiny that is every reactive read feeding
  `renderJBrowseR()`, so a track checkbox opens a track in place instead of
  refetching everything. A `JBrowseRApp()` re-render that changes only
  `session` restores it in place. Any other changed option builds a new
  browser.

- `JBrowseR()` reports `input[[paste0(outputId, "_session")]]` as the user
  navigates and opens tracks, in the same shape `session =` takes and under the
  same name `JBrowseRApp()` already used. "Save this view" is storing that
  value; reopening it is passing it back.

- A browser that fails to build — a genome name nothing answers for, a plugin
  that will not fetch — says so in the widget. It used to leave an empty box
  with the reason only in the browser console.

- Both widgets parse data in a web worker, so a deep BAM or CRAM region no
  longer freezes a Shiny page while it loads. The worker is inlined, which
  doubles each bundle (`JBrowseR.js` 5.0 → 10.0 MB).

# JBrowseR 0.12.0

- New `local_files =` on `JBrowseR()` and `JBrowseRApp()`: open files from your
  own machine with no web server at all. Each path registers under its basename,
  and a track (or an assembly) refers to that name as if it were a URL; a
  conventional sibling index next to it (`.tbi`, `.csi`, `.bai`, `.crai`,
  `.fai`, `.gzi`) is picked up automatically, so an indexed file stays indexed
  and JBrowse reads only the region on screen.

  This is what `serve_data()` was for before 0.11.0 removed it, without the
  hand-rolled HTTP server or the `httpuv` dependency that went with it: the
  bytes travel inside the document and the range reads happen in the browser.
  The advice that replaced it — run `npx http-server --cors` and point at
  `http://localhost:...` — still works and is still right for large files, but
  it cannot produce a knitted document anyone else can open, because a localhost
  URL is dead the moment the HTML leaves your machine.

  The cost is that the bytes ride base64-encoded inside the payload, so this is
  for a file on an analyst's laptop rather than for a reference genome; it warns
  past ~50 MB. (Shiny cannot serve the alternative today: neither
  `addResourcePath()`'s handler nor httpuv's static path answers HTTP `Range`,
  so a URL pointing at either would refetch the whole file per read.)

- New `update_location(outputId, location)`: navigate a browser that is
  already on the page instead of re-rendering it. Feeding a reactive `location`
  into `renderJBrowseR()` rebuilds the whole browser, which refetches its tracks
  and discards the user's zoom, track order, scroll position and feature
  selection — so a Shiny app that moved the view was destroying state to do it.
  This also settles the loop `input$<outputId>_location` used to create: reading
  it in an `observeEvent()` that calls `update_location()` is not circular the
  way reading it in the reactive that feeds the widget is.

  Navigation is the only command, deliberately. A browser's tracks, assembly and
  session can also be swapped live, but each of those has to answer what it does
  to a track the user opened by hand or a layout they rearranged; rebuilding is
  a defensible answer to those and is what re-rendering already does.

- `JBrowseRApp()` now reports `input$<outputId>_selected_feature` and
  `input$<outputId>_location`, the two read-backs `JBrowseR()` already had, so
  an app that grows from one view to several does not have to rewrite its
  server. `_location` is a *list* there, one entry per open view, because the
  app holds any number of them.

- **Breaking:** `JBrowseR()`'s `default_session` is now `session`, matching
  [JBrowseRApp()] and the JS products. It was never a *default* the user's own
  state layered on top of — it is the saved layout to open instead of `tracks`
  and `location`, which is what the app's argument of that name already meant.

- **Breaking:** the global `input$selectedFeature` is gone. Use the namespaced
  `input$<outputId>_selected_feature`, which has been set alongside it since
  0.11.0. The global could not be made correct: two browsers on a page overwrite
  each other's, and inside a Shiny module nothing can read it. The bundled
  example apps show the change; `demos/` was the case in point, where two tabs
  reading the global saw each other's clicks.

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
