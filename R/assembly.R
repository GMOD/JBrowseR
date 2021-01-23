library(stringr)
library(magrittr)

# Interface:
#
# 1. For now, only indexedFasta or bigzipFasta
#
# 2. The name is always guessed from file name
#
# 3. No aliases for now
#
# 4.  If local file, must already be in same directory
#     (or in directory in same place, i.e. data/hg19.fa)

#' Title
#'
#' @param sequence
#' @param bgzip
#'
#' @return
#' @export
#'
#' @examples
assembly <- function(sequence, bgzip = FALSE) {
  if (!bgzip) {
    fa_assembly(sequence)
  } else {
    bgzip_fa_assembly(sequence)
  }
}

fa_assembly <- function(sequence) {
  name <- get_name(sequence)

  # interpolate values into a string of JBrowse configuration
  #
  # note: this gets parsed into JSON in client and used as assembly value
  stringr::str_glue(
    '{{ ',
    '"name": "{name}", ',
    '"sequence": {{ ',
    '"type": "ReferenceSequenceTrack", ',
    '"trackId": "{name}-ReferenceSequenceTrack", ',
    '"adapter": {{ ',
    '"type": "IndexedFastaAdapter", ',
    '"fastaLocation": {{ ',
    '"uri": "{sequence}", ',
    '}}, ',
    '"faiLocation": {{ ',
    '"uri": "{sequence}.fai" ',
    '}}, ',
    '}}, ',
    '}}, ',
    '}}'
  )
}

bgzip_fa_assembly <- function(sequence) {
  name <- get_name(sequence)

  # interpolate values into a string of JBrowse configuration
  #
  # note: this gets parsed into JSON in client and used as assembly value
  stringr::str_glue(
    '{{ ',
    '"name": "{name}", ',
    '"sequence": {{ ',
    '"type": "ReferenceSequenceTrack", ',
    '"trackId": "{name}-ReferenceSequenceTrack", ',
    '"adapter": {{ ',
    '"type": "IndexedFastaAdapter", ',
    '"fastaLocation": {{ ',
    '"uri": "{sequence}", ',
    '}}, ',
    '"faiLocation": {{ ',
    '"uri": "{sequence}.fai" ',
    '}}, ',
    '"gziLocation": {{ ',
    '"uri": "{sequence}.gzi" ',
    '}}, ',
    '}}, ',
    '}}, ',
    '}}'
  )
}


# Helpers

get_name <- function(string) {
  if (is_url(string)) {
    # get assembly name from URL
    name <- parse_url_name(string)
  } else {
    # get assembly name from file
    name <- parse_file_name(string)
  }
}

is_url <- function(string) {
  grepl("www.|http:|https:", string)
}

parse_url_name <- function(url) {
  stringr::str_split(url, "/", simplify = TRUE) %>%
    last_value() %>%
    stringr::str_split("[.]", simplify = TRUE) %>%
    first_value()
}

parse_file_name <- function(path) {
  stringr::str_split(basename(path), "[.]", simplify = TRUE) %>%
    first_value()
}

last_value <- function(x) {
  x[length(x)]
}

first_value <- function(x) {
  x[1]
}

# scratch

# assembly("foo")

# is_url("https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz")
#
# test <- fa_assembly("https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz")
#
# print(test)

# fa_assembly("foo.fa")

