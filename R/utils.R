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
