#' Create a WiggleTrack for a custom JBrowse 2 view
#'
#' Creates the necessary configuration string for a
#' bigWig file so that it can be used
#' in a JBrowse custom linear genome view.
#'
#' @param track_data the URL to the bigWig file
#' @param assembly the config string generated by \code{assembly}
#'
#' @return a character vector of stringified WiggleTrack JSON configuration
#'
#' @export
#'
#' @examples
#' track_wiggle(
#'   "https://jbrowse.org/genomes/hg19/COLO829/colo_normal.bw",
#'   assembly("https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz", bgzip = TRUE)
#' )
track_wiggle <- function(track_data, assembly) {
  check_bw(track_data)

  type <- "QuantitativeTrack"
  name <- get_name(track_data)
  assembly_name <- get_assembly_name(assembly)
  track_id <- stringr::str_c(assembly_name, "_", name)

  as.character(
    stringr::str_glue(
      "{{ ",
      '"type": "{type}", ',
      '"name": "{name}", ',
      '"assemblyNames": ["{assembly_name}"], ',
      '"trackId": "{track_id}", ',
      '"adapter": {{ ',
      '"type": "BigWigAdapter", ',
      '"bigWigLocation": {{ ',
      '"uri": "{track_data}" ',
      "}} ",
      "}} ",
      "}}"
    )
  )
}

check_bw <- function(track_data) {
  track_non_gz <- strip_gz(track_data)

  if (!stringr::str_ends(track_non_gz, ".bw") && !stringr::str_ends(track_non_gz, ".bigWig")) {
    stop("wiggle data must be bigWig (.bw or .bigWig)")
  }
}
