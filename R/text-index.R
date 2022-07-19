#' Create configuration for a JBrowse 2 text index
#'
#' Creates the necessary configuration string for an adapter to a text index for
#' gene name search in the browser.
#'
#' Note: this function currently only supports aggregate indeces.
#'
#' For more information on JBrowse 2 text indeces, visit:
#' \url{https://jbrowse.org/jb2/docs/config_guide/#text-searching}
#'
#' @param ix_uri the URI for the ix file
#' @param ixx_uri the URI for the ixx file
#' @param meta_uri the URI for the JSON metadata file
#' @param assembly the assembly associated with the text index
#'
#' @return a character vector with the JSON text index adapter.
#'
#' @export
#'
#' @examples
#' text_index(
#' "https://jbrowse.org/genomes/hg19/trix/hg19.ix",
#' "https://jbrowse.org/genomes/hg19/trix/hg19.ixx",
#' "https://jbrowse.org/genomes/hg19/trix/meta.json",
#' "hg19"
#' )
text_index <- function(ix_uri, ixx_uri, meta_uri, assembly) {
  id <- paste0(assembly, "-index")

  as.character(
    stringr::str_glue(
      "{{",
      '"type": "TrixTextSearchAdapter", ',
      '"textSearchAdapterId": "{id}", ',
      '"ixFilePath": {{',
      '"uri": "{ix_uri}", ',
      '"locationType": "UriLocation"',
      "}}, ",
      '"ixxFilePath": {{',
      '"uri": "{ixx_uri}", ',
      '"locationType": "UriLocation"',
      "}}, ",
      '"metaFilePath": {{',
      '"uri": "{meta_uri}", ',
      '"locationType": "UriLocation"',
      "}}, ",
      '"assemblyNames": ["{assembly}"]',
      "}}"
    )
  )
}
