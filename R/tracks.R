#' Create an set of tracks for a custom JBrowse 2 view
#'
#' Accepts any number of tracks, returns the configuration
#' string necessary to load these tracks into your JBrowse
#' view.
#'
#' @return
#' @export
#'
#' @examples
#' tracks(track_alignments("alignments.bam", "hg19"))
tracks <- function(...) {
  track_values <- stringr::str_c(..., sep = ", ")
  stringr::str_c("[", track_values, "]")
}

# Interface ---------------------------------------------------------------

# I actually probably want to expose a function per type of track.

# The supported tracks are:

# 'AlignmentsTrack' (done)
# 'VariantTrack'
# 'WiggleTrack'

# and then I want a tracks() function, that takes an arbitrary number
# of tracks, and glues them into a string with [ at the beginning and ]
# at the end, so that it will be the array of tracks in the config
