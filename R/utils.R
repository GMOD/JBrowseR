# base name of a file or URL, without directory or extensions
# "https://x/y/hg19.fa.gz" -> "hg19"
base_name <- function(x) {
  file <- basename(sub("[?#].*$", "", x))
  sub("[.].*$", "", file)
}

# a coalescing operator: `a %||% b` is `a` unless it is NULL. Defined here for
# R (>= 4.1); base R only gained `%||%` in 4.4.
`%||%` <- function(a, b) {
  if (is.null(a)) b else a
}

# drop a single trailing .gz (used by serve_data's track-type sniffing)
strip_gz <- function(x) {
  sub("[.]gz$", "", x)
}

# sequence extensions the view's own guesser recognizes; kept in sync with
# makeAssembly.ts in @jbrowse/embedded-linear-genome-view
SEQUENCE_EXT_RE <- "[.](fa|fasta|fas|fna|mfa|2bit)([.]b?gz)?$"

# true when a string names a sequence file (vs. a hub name like "hg38")
is_sequence_uri <- function(uri) {
  grepl(SEQUENCE_EXT_RE, sub("[?#].*$", "", uri), ignore.case = TRUE)
}

# strip path and sequence extension: ".../hg19.fa.gz" -> "hg19"
assembly_name_from_uri <- function(uri) {
  sub(SEQUENCE_EXT_RE, "", basename(sub("[?#].*$", "", uri)), ignore.case = TRUE)
}
