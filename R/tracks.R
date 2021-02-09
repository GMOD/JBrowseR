#' Create an set of tracks for a custom JBrowse 2 view
#'
#' Accepts any number of tracks, returns the configuration
#' string necessary to load these tracks into your JBrowse
#' view.
#'
#' @param ... The tracks to be added to the JBrowse 2 view
#'
#' @export
#'
#' @examples
#' tracks(track_alignments("alignments.bam", "hg19"))
tracks <- function(...) {
  track_values <- stringr::str_c(..., sep = ", ")
  stringr::str_c("[", track_values, "]")
}
