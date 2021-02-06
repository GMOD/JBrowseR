test_that("creating an alignments track returns the correct string", {
  expect_type(track_variant("foo.vcf", "h19"), "character")
  # test against valid config string
  expect_equal(track_variant(
    "https://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh37/clinvar.vcf.gz",
    assembly("https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz", bgzip = TRUE)
  ), "{ \"type\": \"VariantTrack\", \"name\": \"clinvar\", \"assemblyNames\": [\"hg19\"], \"trackId\": \"hg19_clinvar\", \"adapter\": { \"type\": \"VcfTabixAdapter\", \"vcfGzLocation\": { \"uri\": \"https://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh37/clinvar.vcf.gz\" }, \"index\": { \"location\": { \"uri\": \"https://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh37/clinvar.vcf.gz.tbi\"  } }}}")
  expect_error(track_variant("foo.bcf", "h19"), "variant data must be VCF")
})
