# JBrowseRApp opens views declared as plain JBrowse JSON. A view spec is only
# ever list(type = , init = ) — the same vocabulary JBrowse Web serializes into
# its ?session=spec-... URLs — so there are no R builders for it, and a view
# type JBrowse gains (or one a runtime plugin registers) needs nothing added
# here.

synteny_view_spec <- list(
  type = "LinearSyntenyView",
  init = list(
    # a comparative view's panels are list(assembly=, loc=) per side
    views = list(list(assembly = "hg38"), list(assembly = "mm39")),
    tracks = list("hg38_mm39")
  )
)

paf_track <- list(
  type = "SyntenyTrack",
  trackId = "hg38_mm39",
  name = "hg38 vs mm39",
  assemblyNames = list("hg38", "mm39"),
  adapter = list(
    type = "PAFAdapter",
    targetAssembly = "hg38",
    queryAssembly = "mm39",
    uri = "hg38_mm39.paf"
  )
)

test_that("JBrowseRApp passes assemblies, tracks and views through verbatim", {
  w <- JBrowseRApp(
    assemblies = list(list(name = "hg38"), list(name = "mm39")),
    tracks = list(paf_track),
    views = list(synteny_view_spec)
  )
  expect_equal(w$x$assemblies[[2]]$name, "mm39")
  expect_equal(w$x$tracks[[1]]$adapter$type, "PAFAdapter")
  expect_equal(w$x$views[[1]]$type, "LinearSyntenyView")
  expect_equal(w$x$views[[1]]$init$views[[1]]$assembly, "hg38")
})

test_that("any view type opens with no change to this package", {
  w <- JBrowseRApp(
    assemblies = list(list(name = "hg38")),
    views = list(list(type = "CircularView", init = list(assembly = "hg38")))
  )
  expect_equal(w$x$views[[1]]$type, "CircularView")
})

test_that("a saved session rides along to be restored instead of views", {
  # the round-trip's other half: what a running app reported as
  # input$<id>_session goes back in as `session =`, and reaches the payload
  # unchanged. Whether the session then wins over `views` is the app engine's
  # rule, not this package's, and is covered by a browser render.
  saved <- list(
    name = "saved",
    views = list(list(
      id = "v1", type = "LinearGenomeView", bpPerPx = 73.27, offsetPx = 587433
    ))
  )
  w <- JBrowseRApp(
    assemblies = list(list(name = "hg38")),
    views = list(list(type = "LinearGenomeView", init = list(assembly = "hg38"))),
    session = saved
  )
  expect_equal(w$x$session$views[[1]]$offsetPx, 587433)
  # `views` is still sent: it is what File -> New session returns to
  expect_equal(w$x$views[[1]]$type, "LinearGenomeView")
})

test_that("no session field is sent when none was given", {
  # drop_null keeps the payload free of a null the app would have to interpret
  w <- JBrowseRApp(assemblies = list(list(name = "hg38")))
  expect_false("session" %in% names(w$x))
})

test_that("the app has its own Shiny bindings", {
  # htmlwidgets dispatches on the output element's class, so the app cannot
  # share JBrowseROutput: that emits a JBrowseR-classed div, which loads the
  # single-view bundle and fails to build an app payload
  expect_match(
    as.character(JBrowseRAppOutput("app")),
    'class="JBrowseRApp html-widget'
  )
})

test_that("id fields stay JSON arrays at length one", {
  # the one R-specific trap: a length-1 character vector auto-unboxes to a JSON
  # scalar, so ids that JBrowse reads as arrays are written with list()
  w <- JBrowseRApp(
    assemblies = list(list(name = "hg38")),
    tracks = list(paf_track)
  )
  json <- as.character(jsonlite::toJSON(w$x$tracks[[1]], auto_unbox = TRUE))
  expect_match(json, '"assemblyNames":\\["hg38","mm39"\\]')
})
