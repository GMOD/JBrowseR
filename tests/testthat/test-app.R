# The multi-view helpers build {type, init} view specs and the PAF track config
# that JBrowseRApp() sends to createApp.

test_that("linear_view builds a type/init spec", {
  v <- linear_view("hg38", loc = "chr1:1-1000", tracks = "genes")
  expect_equal(v$type, "LinearGenomeView")
  expect_equal(v$init$assembly, "hg38")
  expect_equal(v$init$loc, "chr1:1-1000")
  expect_equal(v$init$tracks, list("genes"))
})

test_that("linear_view extra args ride onto init", {
  v <- linear_view("hg38", colorByCDS = TRUE)
  expect_true(v$init$colorByCDS)
})

test_that("synteny_view expands assembly names into panels", {
  v <- synteny_view(c("hg38", "mm39"), tracks = "paf", cigar_mode = "full")
  expect_equal(v$type, "LinearSyntenyView")
  expect_equal(v$init$views, list(list(assembly = "hg38"), list(assembly = "mm39")))
  expect_equal(v$init$tracks, list("paf"))
  expect_equal(v$init$cigarMode, "full")
})

test_that("synteny_view accepts panel lists with loc", {
  v <- synteny_view(list(
    list(assembly = "hg38", loc = "chr1"),
    list(assembly = "mm39", loc = "chr1")
  ))
  expect_equal(v$init$views[[1]]$loc, "chr1")
})

test_that("dotplot_view builds a dotplot spec", {
  expect_equal(dotplot_view(c("a", "b"), tracks = "paf")$type, "DotplotView")
})

test_that("synteny_track builds a PAF config spanning two assemblies", {
  t <- synteny_track("data/hg38_mm39.paf", "hg38", "mm39", name = "hg38 vs mm39")
  expect_equal(t$type, "SyntenyTrack")
  expect_equal(t$trackId, "hg38-vs-mm39")
  expect_equal(t$assemblyNames, list("hg38", "mm39"))
  expect_equal(t$adapter$type, "PAFAdapter")
  expect_equal(t$adapter$targetAssembly, "hg38")
  expect_equal(t$adapter$pafLocation$uri, "data/hg38_mm39.paf")
})
