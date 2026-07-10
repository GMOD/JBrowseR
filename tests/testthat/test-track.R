test_that("track() infers type and adapter from extension", {
  expect_equal(track("x/reads.bam")$type, "AlignmentsTrack")
  expect_equal(track("x/reads.bam")$adapter$type, "BamAdapter")
  expect_equal(track("x/reads.cram")$adapter$type, "CramAdapter")
  expect_equal(track("x/calls.vcf.gz")$type, "VariantTrack")
  expect_equal(track("x/calls.vcf.gz")$adapter$type, "VcfTabixAdapter")
  expect_equal(track("x/genes.gff3.gz")$adapter$type, "Gff3TabixAdapter")
  expect_equal(track("x/regions.bed.gz")$adapter$type, "BedTabixAdapter")
  expect_equal(track("x/peaks.bw")$type, "QuantitativeTrack")
  expect_equal(track("x/peaks.bigWig")$adapter$type, "BigWigAdapter")
  expect_equal(track("x/anno.bb")$adapter$type, "BigBedAdapter")
})

test_that("track() defaults name/trackId to the base name and keeps uri", {
  t <- track("https://example.com/data/reads.bam")
  expect_equal(t$name, "reads")
  expect_equal(t$trackId, "reads")
  expect_equal(t$adapter$uri, "https://example.com/data/reads.bam")
})

test_that("track() merges extra config and forces array assembly_names", {
  t <- track("x/reads.bam", assembly_names = "hg19", category = list("Alignments"))
  expect_equal(t$assemblyNames[[1]], "hg19")
  expect_equal(t$category[[1]], "Alignments")
})

test_that("track() errors on an unknown extension", {
  expect_error(track("x/mystery.xyz"), "could not infer")
})

test_that("tracks() collects into a list", {
  tk <- tracks(track("x/a.bam"), track("x/b.vcf.gz"))
  expect_length(tk, 2)
  expect_equal(tk[[2]]$type, "VariantTrack")
})
