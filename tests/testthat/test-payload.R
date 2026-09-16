test_that("options reach the payload verbatim, under JBrowse's names", {
  search <- list(type = "TrixTextSearchAdapter", textSearchAdapterId = "hg38-index")
  x <- JBrowseR(
    assembly = "hg38",
    location = "BRCA1",
    aggregateTextSearchAdapters = list(search),
    configuration = list(theme = list(palette = list(primary = list(main = "#123456")))),
    someOptionJBrowseAddsLater = TRUE
  )$x
  expect_equal(x$assembly, "hg38")
  expect_equal(x$location, "BRCA1")
  expect_equal(x$aggregateTextSearchAdapters, list(search))
  expect_equal(x$configuration$theme$palette$primary$main, "#123456")
  expect_true(x$someOptionJBrowseAddsLater)
})

test_that("a whole options object goes through do.call", {
  path <- tempfile(fileext = ".json")
  on.exit(unlink(path))
  writeLines('{"assemblies": [{"name": "g"}], "views": [{"type": "LinearGenomeView", "assembly": "g"}]}', path)
  x <- do.call(JBrowseRApp, jsonlite::read_json(path))$x
  expect_equal(x$assemblies[[1]]$name, "g")
  expect_equal(x$views[[1]]$type, "LinearGenomeView")
})

test_that("an unnamed option is an error", {
  expect_error(JBrowseR("hg38"), "every option is named")
  expect_error(JBrowseRApp(list("hg38")), "every option is named")
})

test_that("NULL options are left off, and no options is an empty object", {
  x <- JBrowseR(assembly = "hg38", session = NULL)$x
  expect_equal(names(x), "assembly")
  expect_equal(as.character(htmlwidgets:::toJSON2(JBrowseRApp()$x)), "{}")
})
