# all of the strings tested against are valid JBrowse 2 JSON config as strings

test_that("url assemblies return correct string", {
  expect_type(assembly("https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz"), "character")
  expect_equal(assembly("https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz"), "{ \"name\": \"hg19\", \"sequence\": { \"type\": \"ReferenceSequenceTrack\", \"trackId\": \"hg19-ReferenceSequenceTrack\", \"adapter\": { \"type\": \"IndexedFastaAdapter\", \"fastaLocation\": { \"uri\": \"https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz\" }, \"faiLocation\": { \"uri\": \"https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz.fai\" } } } }")
  expect_equal(assembly("https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz", bgzip = TRUE), "{ \"name\": \"hg19\", \"sequence\": { \"type\": \"ReferenceSequenceTrack\", \"trackId\": \"hg19-ReferenceSequenceTrack\", \"adapter\": { \"type\": \"BgzipFastaAdapter\", \"fastaLocation\": { \"uri\": \"https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz\" }, \"faiLocation\": { \"uri\": \"https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz.fai\" }, \"gziLocation\": { \"uri\": \"https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz.gzi\" } } } }")
})

test_that("file assemblies return correct string", {
  expect_type(assembly("data/hg38.fa"), "character")
  expect_equal(assembly("data/hg38.fa"), "{ \"name\": \"hg38\", \"sequence\": { \"type\": \"ReferenceSequenceTrack\", \"trackId\": \"hg38-ReferenceSequenceTrack\", \"adapter\": { \"type\": \"IndexedFastaAdapter\", \"fastaLocation\": { \"uri\": \"data/hg38.fa\" }, \"faiLocation\": { \"uri\": \"data/hg38.fa.fai\" } } } }")
  expect_equal(assembly("data/hg38.fa", bgzip = TRUE), "{ \"name\": \"hg38\", \"sequence\": { \"type\": \"ReferenceSequenceTrack\", \"trackId\": \"hg38-ReferenceSequenceTrack\", \"adapter\": { \"type\": \"BgzipFastaAdapter\", \"fastaLocation\": { \"uri\": \"data/hg38.fa\" }, \"faiLocation\": { \"uri\": \"data/hg38.fa.fai\" }, \"gziLocation\": { \"uri\": \"data/hg38.fa.gzi\" } } } }")
})
