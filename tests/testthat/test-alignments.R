test_that("creating an alignments track returns the correct string", {
  expect_type(track_alignments("foo.bam", "h19"), "character")
  # test output against working track configs
  expect_equal(track_alignments("https://s3.amazonaws.com/jbrowse.org/genomes/hg19/skbr3/reads_lr_skbr3.fa_ngmlr-0.2.3_mapped.down.bam",
    assembly = assembly("https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz", bgzip = TRUE)
  ), "{\"type\": \"AlignmentsTrack\", \"name\": \"reads_lr_skbr3\", \"assemblyNames\": [\"hg19\"], \"trackId\": \"hg19_reads_lr_skbr3\", \"adapter\": { \"type\": \"BamAdapter\", \"bamLocation\": { \"uri\": \"https://s3.amazonaws.com/jbrowse.org/genomes/hg19/skbr3/reads_lr_skbr3.fa_ngmlr-0.2.3_mapped.down.bam\" }, \"index\": { \"location\": { \"uri\": \"https://s3.amazonaws.com/jbrowse.org/genomes/hg19/skbr3/reads_lr_skbr3.fa_ngmlr-0.2.3_mapped.down.bam.bai\" } } } }")

})
