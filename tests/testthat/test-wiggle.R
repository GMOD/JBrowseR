test_that("creating a wiggle track returns the correct string", {
  assembly <- assembly("https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz", bgzip = TRUE)

  expect_type(track_wiggle("foo.bw", assembly), "character")
  # test against valid config for the URL
  expect_equal(track_wiggle(
    "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/reads_lr_skbr3.fa_ngmlr-0.2.3_mapped.bam.regions.bw",
    assembly
  ), "{ \"type\": \"QuantitativeTrack\", \"name\": \"reads_lr_skbr3\", \"assemblyNames\": [\"hg19\"], \"trackId\": \"hg19_reads_lr_skbr3\", \"adapter\": { \"type\": \"BigWigAdapter\", \"bigWigLocation\": { \"uri\": \"https://s3.amazonaws.com/jbrowse.org/genomes/hg19/reads_lr_skbr3.fa_ngmlr-0.2.3_mapped.bam.regions.bw\" } } }")
  expect_error(track_wiggle("foo.bz", assembly), "wiggle data must be bigWig \\(.bw or .bigWig\\)")
})
