# The widget constructors send createLinearGenomeView/createApp options verbatim
# (camelCase); these check the payload built into the htmlwidget's `x`.

test_that("JBrowseR builds a camelCase LinearGenomeView payload", {
  x <- JBrowseR(
    "hg38",
    location = "BRCA1",
    text_search = text_index("a.ix", "a.ixx", "meta.json", "hg38"),
    theme = theme("#123456")
  )$x
  expect_equal(x$assembly, "hg38")
  expect_equal(x$location, "BRCA1")
  # a single text_index() adapter is wrapped into the array the view wants
  expect_equal(x$aggregateTextSearchAdapters[[1]]$type, "TrixTextSearchAdapter")
  expect_equal(x$configuration$theme$palette$primary$main, "#123456")
  # no legacy wire fields leak through (exact names: `config` would otherwise
  # partial-match `configuration`)
  expect_false(any(c("config", "textSearch", "theme") %in% names(x)))
})

test_that("explicit args override a config base", {
  x <- JBrowseR("hg38", config = list(assembly = "old", tracks = list("t")))$x
  expect_equal(x$assembly, "hg38")
  expect_equal(x$tracks, list("t"))
})

test_that("JBrowseRApp sends assemblies/tracks/views for createApp", {
  x <- JBrowseRApp(
    assemblies = list(assembly("g.fa")),
    views = list(view("LinearGenomeView", assembly = "g"))
  )$x
  expect_length(x$assemblies, 1)
  expect_equal(x$views[[1]]$type, "LinearGenomeView")
})

test_that("both widgets require an assembly or a config", {
  expect_error(JBrowseR(), "assembly")
  expect_error(JBrowseRApp(), "assemblies")
})
