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
