#' Create a set of tracks for a custom JBrowse 2 view
#'
#' Accepts any number of tracks, returns the configuration
#' string necessary to load these tracks into your JBrowse
#' view.
#'
#' @param ... The tracks to be added to the JBrowse 2 view
#'
#' @return a character vector of stringified JSON configuration for
#'   all tracks to add to the browser
#'
#' @export
#'
#' @examples
#' # create an assembly configuration and alignments track
#' assembly <- assembly("https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz", bgzip = TRUE)
#' alignments <- track_alignments("alignments.bam", assembly)
#'
#' # create a tracks configuration with the alignments track
#' tracks(alignments)
tracks <- function(...) {
  track_values <- stringr::str_c(..., sep = ", ")
  stringr::str_c("[", track_values, "]")
}
