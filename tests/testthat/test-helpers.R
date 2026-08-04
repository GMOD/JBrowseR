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

test_that("track_data_frame() carries extra columns onto each feature", {
  df <- data.frame(chrom = "1", start = 1, end = 9, name = "f", pvalue = 0.01)
  f <- track_data_frame(df, "t")$adapter$features[[1]]
  expect_equal(f$pvalue, 0.01)
  expect_equal(f$uniqueId, "t-1")
})

test_that("track_data_frame() rejects missing columns", {
  expect_error(track_data_frame(data.frame(x = 1), "t"), "missing required")
})

test_that("track_data_frame() without score is a FeatureTrack", {
  df <- data.frame(chrom = "1", start = 1, end = 9, name = "f")
  expect_equal(track_data_frame(df, "t")$type, "FeatureTrack")
})
