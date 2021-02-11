test_that("creating a feature track returns the correct string", {
  assembly <- assembly(
    "https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz",
    bgzip = TRUE,
    aliases = c("GRCh37"),
    refname_aliases = "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/hg19_aliases.txt"
  )

  expect_equal(
    track_feature(
      "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/ncbi_refseq/GRCh37_latest_genomic.sort.gff.gz",
      assembly
    ),
    "{ \"type\": \"FeatureTrack\", \"name\": \"GRCh37_latest_genomic\", \"assemblyNames\": [\"hg19\"], \"trackId\": \"hg19_GRCh37_latest_genomic\", \"adapter\": { \"type\": \"Gff3TabixAdapter\", \"gffGzLocation\": { \"uri\": \"https://s3.amazonaws.com/jbrowse.org/genomes/hg19/ncbi_refseq/GRCh37_latest_genomic.sort.gff.gz\" }, \"index\": { \"location\": { \"uri\": \"https://s3.amazonaws.com/jbrowse.org/genomes/hg19/ncbi_refseq/GRCh37_latest_genomic.sort.gff.gz.tbi\"  } }}}"
  )

  expect_error(
    track_feature(
      "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/ncbi_refseq/GRCh37_latest_genomic.sort.pff.gz",
      assembly
    ),
    "feature data must be GFF3. Use .gff or .gff3 extension"
  )
})
