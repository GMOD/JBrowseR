# `local_files` ships bytes into the browser instead of serving them over HTTP.
# The wire format is jsonlite's: a raw vector becomes a base64 string, which
# srcjs/widget.ts decodes. These check the R half — that the right bytes are
# registered under the names a track config refers to.

write_temp <- function(name, bytes = as.raw(1:4)) {
  path <- file.path(tempfile("local"), name)
  dir.create(dirname(path), recursive = TRUE)
  writeBin(bytes, path)
  path
}

test_that("a path registers its bytes under its basename", {
  path <- write_temp("peaks.bed.gz", as.raw(c(31, 139, 8)))
  x <- JBrowseR("hg38", local_files = path)$x
  expect_equal(names(x$localFiles), "peaks.bed.gz")
  expect_equal(x$localFiles[["peaks.bed.gz"]], as.raw(c(31, 139, 8)))
})

# The adapter asks for its index by deriving the name from the data file's, so
# an index registered under any other name is one JBrowse never finds — and the
# symptom is an unindexed-looking track rather than an error.
test_that("a sibling index is picked up under the name the adapter derives", {
  path <- write_temp("peaks.bed.gz")
  writeBin(as.raw(9), paste0(path, ".tbi"))
  x <- JBrowseR("hg38", local_files = path)$x
  expect_setequal(names(x$localFiles), c("peaks.bed.gz", "peaks.bed.gz.tbi"))
  expect_equal(x$localFiles[["peaks.bed.gz.tbi"]], as.raw(9))
})

test_that("only a matching sibling is picked up", {
  path <- write_temp("reads.bam")
  writeBin(as.raw(9), paste0(path, ".bai"))
  writeBin(as.raw(9), paste0(path, ".notanindex"))
  x <- JBrowseR("hg38", local_files = path)$x
  expect_setequal(names(x$localFiles), c("reads.bam", "reads.bam.bai"))
})

test_that("several files, and a name given explicitly", {
  a <- write_temp("a.bw", as.raw(1))
  b <- write_temp("b.bw", as.raw(2))
  x <- JBrowseR("hg38", local_files = c(a, "renamed.bw" = b))$x
  expect_setequal(names(x$localFiles), c("a.bw", "renamed.bw"))
  expect_equal(x$localFiles[["renamed.bw"]], as.raw(2))
})

test_that("bytes already in memory can be passed directly", {
  x <- JBrowseR("hg38", local_files = list(`x.bed` = as.raw(c(7, 8))))$x
  expect_equal(x$localFiles[["x.bed"]], as.raw(c(7, 8)))
})

test_that("JBrowseRApp takes local_files too", {
  path <- write_temp("reads.bam")
  x <- JBrowseRApp(assemblies = list("hg38"), local_files = path)$x
  expect_equal(names(x$localFiles), "reads.bam")
})

test_that("no local_files leaves the field off the payload", {
  expect_false("localFiles" %in% names(JBrowseR("hg38")$x))
})

# Each of these is a mistake with no good reading, and each fails silently if
# it is allowed through: a missing file registers nothing, a duplicate name
# drops one of the two files, and an unnamed raw vector cannot be referred to.
test_that("mistakes are reported rather than half-applied", {
  expect_error(JBrowseR("hg38", local_files = "no/such/file.bam"), "does not exist")
  path <- write_temp("dup.bw")
  expect_error(
    JBrowseR("hg38", local_files = c("same" = path, "same" = path)),
    "two entries named"
  )
  expect_error(
    JBrowseR("hg38", local_files = list(as.raw(1))),
    "needs a name"
  )
  expect_error(JBrowseR("hg38", local_files = 42), "file paths")
})

# The bytes travel base64-encoded inside the document, so a large file makes a
# document nobody can open rather than a slow request.
test_that("an oversized set warns before it is embedded", {
  big <- raw(SIZE_WARN_BYTES + 1)
  expect_warning(
    JBrowseR("hg38", local_files = list(`big.bw` = big)),
    "base64"
  )
})

# The payload is the widget's `x`, so this is what actually reaches the browser:
# jsonlite renders a raw vector as base64 and htmlwidgets unboxes it, which is
# the whole transport. srcjs/widget.ts decodes exactly this.
test_that("bytes serialize as base64 in the widget payload", {
  x <- JBrowseR("hg38", local_files = list(`x.bed` = as.raw(c(1, 2, 255))))$x
  json <- jsonlite::fromJSON(htmlwidgets:::toJSON2(x))
  expect_equal(json$localFiles$x.bed, "AQL/")
})
