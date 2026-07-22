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
