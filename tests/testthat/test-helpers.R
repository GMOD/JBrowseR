test_that("theme() nests palette colors, omitting absent ones", {
  th <- theme("#311b92", "#0097a7")
  expect_equal(th$palette$primary$main, "#311b92")
  expect_equal(th$palette$secondary$main, "#0097a7")
  expect_null(th$palette$tertiary)
})

test_that("text_index() builds a Trix aggregate adapter", {
  ix <- text_index("a.ix", "a.ixx", "meta.json", "hg19")
  expect_equal(ix$type, "TrixTextSearchAdapter")
  expect_equal(ix$textSearchAdapterId, "hg19-index")
  expect_equal(ix$ixFilePath$uri, "a.ix")
  expect_equal(ix$assemblyNames[[1]], "hg19")
})

test_that("track_data_frame() emits FromConfigAdapter features", {
  df <- data.frame(
    chrom = c("1", "2"),
    start = c(1, 2),
    end = c(9, 10),
    name = c("f1", "f2"),
    score = c(5, 6)
  )
  t <- track_data_frame(df, "peaks", "hg19")
  expect_equal(t$type, "QuantitativeTrack")
  expect_equal(t$trackId, "hg19_peaks")
  expect_equal(t$adapter$type, "FromConfigAdapter")
  expect_length(t$adapter$features, 2)
  expect_equal(t$adapter$features[[1]]$refName, "1")
  expect_equal(t$adapter$features[[2]]$score, 6)
})

test_that("track_data_frame() rejects missing columns", {
  expect_error(track_data_frame(data.frame(x = 1), "t"), "missing required")
})

test_that("track_data_frame() without score is a FeatureTrack", {
  df <- data.frame(chrom = "1", start = 1, end = 9, name = "f")
  expect_equal(track_data_frame(df, "t")$type, "FeatureTrack")
})

test_that("backfill_assembly_names fills only missing assemblyNames", {
  tk <- list(
    track("x/a.bam"),
    track("x/b.vcf.gz", assembly_names = "custom")
  )
  filled <- JBrowseR:::backfill_assembly_names(tk, "hg19")
  expect_equal(filled[[1]]$assemblyNames[[1]], "hg19")
  expect_equal(filled[[2]]$assemblyNames[[1]], "custom")
})
