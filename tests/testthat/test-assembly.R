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

test_that("assembly_name derives from a sequence URL but not a hub name", {
  # a bare FASTA URL as the assembly is named after the file (the view's
  # makeAssembly does the same), so backfill uses the derived name
  expect_equal(assembly_name("https://x.org/data/hg38.fa.gz?t=1"), "hg38")
  expect_equal(assembly_name("genome.2bit"), "genome")
  # a hub name (or GenArk accession) is itself the resolved name
  expect_equal(assembly_name("hg38"), "hg38")
  expect_equal(assembly_name("GCF_000001405.40"), "GCF_000001405.40")
})
