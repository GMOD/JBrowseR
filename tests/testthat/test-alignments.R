test_that("creating an alignments track returns the correct string", {
  expect_type(track_alignments("foo.bam", "h19"), "character")
  # test output against working track configs
  expect_equal(track_alignments("https://s3.amazonaws.com/jbrowse.org/genomes/hg19/skbr3/reads_lr_skbr3.fa_ngmlr-0.2.3_mapped.down.bam",
    assembly = assembly("https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz", bgzip = TRUE)
  ), "{\"type\": \"AlignmentsTrack\", \"name\": \"reads_lr_skbr3\", \"assemblyNames\": [\"hg19\"], \"trackId\": \"hg19_reads_lr_skbr3\", \"adapter\": { \"type\": \"BamAdapter\", \"bamLocation\": { \"uri\": \"https://s3.amazonaws.com/jbrowse.org/genomes/hg19/skbr3/reads_lr_skbr3.fa_ngmlr-0.2.3_mapped.down.bam\" }, \"index\": { \"location\": { \"uri\": \"https://s3.amazonaws.com/jbrowse.org/genomes/hg19/skbr3/reads_lr_skbr3.fa_ngmlr-0.2.3_mapped.down.bam.bai\" } } } }")
  expect_equal(track_alignments(
    "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/ultra-long-ont_hs37d5_phased.cram",
    assembly = assembly("https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz", bgzip = TRUE)
  ), "{\"type\": \"AlignmentsTrack\", \"name\": \"ultra-long-ont_hs37d5_phased\", \"assemblyNames\": [\"hg19\"], \"trackId\": \"hg19_ultra-long-ont_hs37d5_phased\", \"adapter\": { \"type\": \"CramAdapter\", \"cramLocation\": { \"uri\": \"https://s3.amazonaws.com/jbrowse.org/genomes/hg19/ultra-long-ont_hs37d5_phased.cram\" }, \"craiLocation\": { \"uri\": \"https://s3.amazonaws.com/jbrowse.org/genomes/hg19/ultra-long-ont_hs37d5_phased.cram.crai\" }, \"sequenceAdapter\": { \"type\": \"BgzipFastaAdapter\",  \"fastaLocation\": { \"uri\": \"https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz\" },  \"faiLocation\": { \"uri\": \"https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz.fai\" },  \"gziLocation\": { \"uri\": \"https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz.gzi\" } }  } }")
  expect_error(track_alignments("foo.bar", "hg19"), "alignment data must be either BAM or CRAM")
})
