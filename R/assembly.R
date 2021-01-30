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

#' Create an assembly for a custom RBrowse view
#'
#' Creates the necessary configuration string for an
#' indexed fasta or bgzip fasta so that it can be used
#' as the assembly in a RBrowse custom linear genome view.
#'
#' The string returned by \code{assembly} is stringified JSON.
#' RBrowse is an interface to JBrowse 2, which receives its
#' configuration in JSON format. The stringified JSON returned
#' by \code{assembly} is parsed into a JavaScript object in the
#' browser, and is used to configure the genome browser.
#'
#' It is important to note that while only the fasta file is
#' passed as an argument, \code{assembly} assumes that a fasta
#' index of the same name is located with the fasta file (as
#' well as a gzi file in the case of a bgzip fasta).
#'
#' For example:
#'
#' \code{assembly("data/hg38.fa")}
#'
#' Assumes that \code{data/hg38.fa.fai} also exists.
#'
#' \code{assembly("data/hg38.fa", bgzip = TRUE)}
#'
#' Assumes that \code{data/hg38.fa.fai} and \code{data/hg38.fa.gzi} both exist.
#'
#' This is a JBrowse 2 convention, and the default naming output of samtools
#' and bgzip.
#'
#' For more information on creating these files, visit
#' \url{https://jbrowse.org/jb2/docs/quickstart_cli#adding-a-genome-assembly}
#'
#' @param sequence the URL or file path to your fasta file
#' @param bgzip whether or not your fasta is bgzip compressed
#'
#' @return a string of RBrowse assembly configuration
#' @export
#'
#' @importFrom magrittr "%>%"
#' @examples
#' assembly("https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz")
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
  as.character(
    stringr::str_glue(
      "{{ ",
      '"name": "{name}", ',
      '"sequence": {{ ',
      '"type": "ReferenceSequenceTrack", ',
      '"trackId": "{name}-ReferenceSequenceTrack", ',
      '"adapter": {{ ',
      '"type": "IndexedFastaAdapter", ',
      '"fastaLocation": {{ ',
      '"uri": "{sequence}" ',
      "}}, ",
      '"faiLocation": {{ ',
      '"uri": "{sequence}.fai" ',
      "}} ",
      "}} ",
      "}} ",
      "}}"
    )
  )
}

bgzip_fa_assembly <- function(sequence) {
  name <- get_name(sequence)

  # interpolate values into a string of JBrowse configuration
  #
  # note: this gets parsed into JSON in client and used as assembly value
  as.character(
    stringr::str_glue(
      "{{ ",
      '"name": "{name}", ',
      '"sequence": {{ ',
      '"type": "ReferenceSequenceTrack", ',
      '"trackId": "{name}-ReferenceSequenceTrack", ',
      '"adapter": {{ ',
      '"type": "BgzipFastaAdapter", ',
      '"fastaLocation": {{ ',
      '"uri": "{sequence}" ',
      "}}, ",
      '"faiLocation": {{ ',
      '"uri": "{sequence}.fai" ',
      "}}, ",
      '"gziLocation": {{ ',
      '"uri": "{sequence}.gzi" ',
      "}} ",
      "}} ",
      "}} ",
      "}}"
    )
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
