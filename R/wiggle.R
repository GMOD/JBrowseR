# Note: -------------------------------------------------------------------

# this currently isn't working, where the track draws nothing. I think
# it is some issue with displayTypes, since WiggleTrack from the docs
# no longer exists, and I need to use QuantitativeTrack

#' Title
#'
#' @param track_data
#' @param assembly
#'
#' @return
#' @export
#'
#' @examples
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
