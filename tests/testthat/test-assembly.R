test_that("assembly() builds a uri-shorthand config with autodetected adapter", {
  a <- assembly("https://example.com/hg19.fa.gz", aliases = "GRCh37")
  expect_equal(a$name, "hg19")
  expect_equal(a$sequence$trackId, "hg19-ReferenceSequenceTrack")
  expect_equal(a$sequence$adapter$type, "BgzipFastaAdapter")
  expect_equal(a$sequence$adapter$uri, "https://example.com/hg19.fa.gz")
  # aliases stays a JSON array even at length 1
  expect_type(a$aliases, "list")
  expect_equal(a$aliases[[1]], "GRCh37")
})

test_that("assembly() uses IndexedFastaAdapter for plain fasta", {
  a <- assembly("https://example.com/genome.fa")
  expect_equal(a$sequence$adapter$type, "IndexedFastaAdapter")
  expect_null(a$aliases)
})

test_that("assembly() attaches refNameAliases when given", {
  a <- assembly("g.fa", refname_aliases = "https://example.com/aliases.txt")
  expect_equal(a$refNameAliases$adapter$type, "RefNameAliasAdapter")
  expect_equal(a$refNameAliases$adapter$uri, "https://example.com/aliases.txt")
})
