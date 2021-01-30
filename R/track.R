#' Title
#'
#' @param type
#' @param track_file
#'
#' @return
#' @export
#'
#' @examples
track <- function(type, track_file, assembly_name) {
  switch (type,
    AlignmentsTrack = alignments_track(track_file, assembly_name)
  )
}

alignments_track <- function(track_file, assembly_name) {
  print("It's an alignments track!")
  type <- "AlignmentsTrack"
  name <- get_name(track_file)
  track_id <- paste(assembly_name, "_", name)



}

# Interface ---------------------------------------------------------------

# I actually probably want to expose a function per type of track.

# The supported tracks are:

# 'AlignmentsTrack'
# 'PileupTrack'
# 'SNPCoverageTrack'
# 'VariantTrack'
# 'WiggleTrack'

# and then I want a track() function, that takes an arbitrary number
# of tracks, and glues them into a string with [ at the beginning and ]
# at the end, so that it will be the array of tracks in the config
