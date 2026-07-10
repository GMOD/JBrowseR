test_that("track() infers type and adapter from extension", {
  expect_equal(track("x/reads.bam")$type, "AlignmentsTrack")
  expect_equal(track("x/reads.bam")$adapter$type, "BamAdapter")
  expect_equal(track("x/reads.cram")$adapter$type, "CramAdapter")
  expect_equal(track("x/calls.vcf.gz")$type, "VariantTrack")
  expect_equal(track("x/calls.vcf.gz")$adapter$type, "VcfTabixAdapter")
  expect_equal(track("x/genes.gff3.gz")$adapter$type, "Gff3TabixAdapter")
  expect_equal(track("x/regions.bed.gz")$adapter$type, "BedTabixAdapter")
  expect_equal(track("x/genes.gtf.gz")$adapter$type, "GtfTabixAdapter")
  expect_equal(track("x/peaks.bw")$type, "QuantitativeTrack")
  expect_equal(track("x/peaks.bigWig")$adapter$type, "BigWigAdapter")
  expect_equal(track("x/anno.bb")$adapter$type, "BigBedAdapter")
  expect_equal(track("x/contact.hic")$type, "HicTrack")
  expect_equal(track("x/contact.hic")$adapter$type, "HicAdapter")
})

test_that("track() uses the uri shorthand when no index override is given", {
  expect_equal(
    track("x/reads.bam")$adapter,
    list(type = "BamAdapter", uri = "x/reads.bam")
  )
})

test_that("track() switches to longhand slots for an explicit index", {
  bam <- track("x/reads.bam", index = "x/other.bai")$adapter
  expect_equal(bam$bamLocation$uri, "x/reads.bam")
  expect_equal(bam$index$location$uri, "x/other.bai")
  expect_equal(bam$index$indexType, "BAI")
  expect_null(bam$uri)

  cram <- track("x/reads.cram", index = "x/other.crai")$adapter
  expect_equal(cram$cramLocation$uri, "x/reads.cram")
  expect_equal(cram$craiLocation$uri, "x/other.crai")
})

test_that("track() detects a .csi index by extension", {
  vcf <- track("x/calls.vcf.gz", index = "x/calls.vcf.gz.csi")$adapter
  expect_equal(vcf$index$indexType, "CSI")
})

test_that("track() rejects an index on an unindexed format", {
  expect_error(track("x/peaks.bw", index = "x/peaks.bw.idx"), "no index file")
})

test_that("track() picks the tabix adapter when bgzipped, plain otherwise", {
  expect_equal(track("x/g.gff.gz")$adapter$type, "Gff3TabixAdapter")
  expect_equal(track("x/g.gff")$adapter$type, "Gff3Adapter")
  expect_equal(track("x/g.gtf.gz")$adapter$type, "GtfTabixAdapter")
  expect_equal(track("x/g.gtf")$adapter$type, "GtfAdapter")
  expect_equal(track("x/r.bed.gz")$adapter$type, "BedTabixAdapter")
  expect_equal(track("x/r.bed")$adapter$type, "BedAdapter")
  expect_equal(track("x/v.vcf.gz")$adapter$type, "VcfTabixAdapter")
  expect_equal(track("x/v.vcf")$adapter$type, "VcfAdapter")
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

test_that("normalize_track expands a bare URL string", {
  t <- normalize_track("x/reads.cram")
  expect_equal(t$type, "AlignmentsTrack")
  expect_equal(t$adapter, list(type = "CramAdapter", uri = "x/reads.cram"))
})

test_that("normalize_track expands a c(url, index) pair", {
  t <- normalize_track(c("x/reads.bam", "x/reads.bam.bai"))
  expect_equal(t$adapter$bamLocation$uri, "x/reads.bam")
  expect_equal(t$adapter$index$location$uri, "x/reads.bam.bai")
})

test_that("normalize_track leaves a track config list untouched", {
  conf <- list(type = "FeatureTrack", trackId = "custom", name = "custom")
  expect_identical(normalize_track(conf), conf)
})

test_that("backfill_assembly_names expands bare strings and fills the assembly", {
  out <- backfill_assembly_names(list("x/reads.cram"), "hg38")
  expect_equal(out[[1]]$adapter$type, "CramAdapter")
  expect_equal(out[[1]]$assemblyNames, list("hg38"))
})
