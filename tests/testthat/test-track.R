# Track-type/adapter inference AND assemblyNames backfill now live in JBrowse
# core: the view expands a loose list(uri = ...) spec at display time via the
# same format plugins the "Add track" flow uses, and stamps its single assembly
# onto any track that omits assemblyNames. These tests cover only the R-side spec
# building.

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
