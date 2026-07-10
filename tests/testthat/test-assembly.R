test_that("assembly() builds the flat { name, uri } shorthand (core expands it)", {
  a <- assembly("https://example.com/hg19.fa.gz", aliases = "GRCh37")
  expect_equal(a$name, "hg19")
  # no sequence track or adapter type is chosen in R; core expands the flat uri
  expect_null(a$sequence)
  expect_equal(a$uri, "https://example.com/hg19.fa.gz")
  # aliases stays a JSON array even at length 1
  expect_type(a$aliases, "list")
  expect_equal(a$aliases[[1]], "GRCh37")
})

test_that("assembly() passes plain and 2bit sequences through as flat uris", {
  expect_equal(assembly("https://example.com/genome.fa")$uri,
    "https://example.com/genome.fa")
  expect_equal(assembly("https://example.com/hg38.2bit")$uri,
    "https://example.com/hg38.2bit")
  expect_null(assembly("https://example.com/genome.fa")$sequence)
  expect_null(assembly("https://example.com/genome.fa")$aliases)
})

test_that("assembly() attaches a bare { uri } refNameAliases shorthand", {
  a <- assembly("g.fa", refname_aliases = "https://example.com/aliases.txt")
  # the alias adapter type is boilerplate core fills in
  expect_null(a$refNameAliases$adapter)
  expect_equal(a$refNameAliases$uri, "https://example.com/aliases.txt")
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
