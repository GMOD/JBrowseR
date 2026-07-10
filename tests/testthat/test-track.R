# Track-type/adapter inference now lives in JBrowse core: the view expands a
# loose list(uri = ..., index = ...) spec at display time via the same format
# plugins the "Add track" flow uses. These tests cover only the R-side spec
# building and assemblyNames backfill — the inference itself is core's.

test_that("track() builds a loose uri spec", {
  expect_equal(track("x/reads.bam"), list(uri = "x/reads.bam"))
})

test_that("track() carries name, track_id, and index", {
  t <- track("x/reads.bam", name = "Reads", track_id = "reads", index = "x/o.bai")
  expect_equal(t$uri, "x/reads.bam")
  expect_equal(t$name, "Reads")
  expect_equal(t$trackId, "reads")
  expect_equal(t$index, "x/o.bai")
})

test_that("track() forces assembly_names to an array and merges extra config", {
  t <- track(
    "x/reads.bam",
    assembly_names = "hg19",
    category = list("Alignments"),
    type = "AlignmentsTrack"
  )
  expect_equal(t$assemblyNames[[1]], "hg19")
  expect_equal(t$category[[1]], "Alignments")
  expect_equal(t$type, "AlignmentsTrack")
})

test_that("tracks() collects into a list", {
  tk <- tracks(track("x/a.bam"), track("x/b.vcf.gz"))
  expect_length(tk, 2)
  expect_equal(tk[[2]]$uri, "x/b.vcf.gz")
})

test_that("normalize_track expands a bare URL string", {
  expect_equal(normalize_track("x/reads.cram"), list(uri = "x/reads.cram"))
})

test_that("normalize_track expands a c(url, index) pair", {
  expect_equal(
    normalize_track(c("x/reads.bam", "x/reads.bam.bai")),
    list(uri = "x/reads.bam", index = "x/reads.bam.bai")
  )
})

test_that("normalize_track leaves a track config list untouched", {
  conf <- list(type = "FeatureTrack", trackId = "custom", name = "custom")
  expect_identical(normalize_track(conf), conf)
})

test_that("backfill_assembly_names expands bare strings and fills the assembly", {
  out <- backfill_assembly_names(list("x/reads.cram"), "hg38")
  expect_equal(out[[1]]$uri, "x/reads.cram")
  expect_equal(out[[1]]$assemblyNames, list("hg38"))
})
