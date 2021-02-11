#' Create an assembly for a custom JBrowse view
#'
#' Creates the necessary configuration string for an
#' indexed fasta or bgzip fasta so that it can be used
#' as the assembly in a JBrowse custom linear genome view.
#'
#' The string returned by \code{assembly} is stringified JSON.
#' JBrowseR is an interface to JBrowse 2, which receives its
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
#' @param assembly_data the URL or file path to your fasta file
#' @param bgzip whether or not your fasta is bgzip compressed
#' @param aliases a vector of strings of the aliases for the assembly
#' @param refname_aliases the URL or file path to a file containing reference
#'   name aliases. For more info see
#'   \url{https://jbrowse.org/jb2/docs/config_guide#configuring-reference-name-aliasing}
#'
#' @return a string of RBrowse assembly configuration
#' @export
#'
#' @examples
#' assembly("https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz", bgzip = TRUE)
assembly <- function(assembly_data, bgzip = FALSE, aliases = NULL, refname_aliases = NULL) {
  if (!bgzip) {
    fa_assembly(assembly_data, aliases, refname_aliases)
  } else {
    bgzip_fa_assembly(assembly_data, aliases, refname_aliases)
  }
}

fa_assembly <- function(assembly_data, aliases, refname_aliases) {
  name <- get_name(assembly_data)
  aliases <- get_aliases(aliases)
  refname_aliases <- get_refname_aliases(refname_aliases)

  # interpolate values into a string of JBrowse configuration
  #
  # note: this gets parsed into JSON in client and used as assembly value
  as.character(
    stringr::str_glue(
      "{{ ",
      '"name": "{name}", ',
      "{aliases}",
      '"sequence": {{ ',
      '"type": "ReferenceSequenceTrack", ',
      '"trackId": "{name}-ReferenceSequenceTrack", ',
      '"adapter": {{ ',
      '"type": "IndexedFastaAdapter", ',
      '"fastaLocation": {{ ',
      '"uri": "{assembly_data}" ',
      "}}, ",
      '"faiLocation": {{ ',
      '"uri": "{assembly_data}.fai" ',
      "}} ",
      "}} ",
      "}} ",
      "{refname_aliases}",
      "}}"
    )
  )
}

bgzip_fa_assembly <- function(assembly_data, aliases, refname_aliases) {
  name <- get_name(assembly_data)
  aliases <- get_aliases(aliases)
  refname_aliases <- get_refname_aliases(refname_aliases)

  # interpolate values into a string of JBrowse configuration
  #
  # note: this gets parsed into JSON in client and used as assembly value
  as.character(
    stringr::str_glue(
      "{{ ",
      '"name": "{name}", ',
      "{aliases}",
      '"sequence": {{ ',
      '"type": "ReferenceSequenceTrack", ',
      '"trackId": "{name}-ReferenceSequenceTrack", ',
      '"adapter": {{ ',
      '"type": "BgzipFastaAdapter", ',
      '"fastaLocation": {{ ',
      '"uri": "{assembly_data}" ',
      "}}, ",
      '"faiLocation": {{ ',
      '"uri": "{assembly_data}.fai" ',
      "}}, ",
      '"gziLocation": {{ ',
      '"uri": "{assembly_data}.gzi" ',
      "}} ",
      "}} ",
      "}} ",
      "{refname_aliases}",
      "}}"
    )
  )
}

# create a JSON array of aliases for the config
# c("hg19", "GRCh37") -> "aliases": ["hg19", "GRCh37"]
get_aliases <- function(aliases) {
  if (!is.null(aliases)) {
    for (i in seq_along(aliases)) {
      aliases[i] <- stringr::str_c('"', aliases[i], '"')
    }

    alias_array <- stringr::str_c(
      "[",
      stringr::str_c(aliases, collapse = ", "),
      "]"
    )

    stringr::str_c(
      '"aliases": ',
      alias_array,
      ", "
    )
  } else {
    ""
  }
}

get_refname_aliases <- function(refname_aliases) {
  if (!is.null(refname_aliases)) {
    as.character(
      stringr::str_glue(
        ', "refNameAliases": {{ ',
        '"adapter": {{ ',
        '"type": "RefNameAliasAdapter", ',
        '"location": {{ ',
        '"uri": "{refname_aliases}" ',
        "}} ",
        "}} ",
        "}} "
      )
    )
  } else {
    ""
  }
}
