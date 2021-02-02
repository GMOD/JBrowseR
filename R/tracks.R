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


#' Create an AlignmentsTrack for a custom JBrowse 2 view
#'
#' Creates the necessary configuration string for an
#' indexed BAM or CRAM alignment so that it can be used
#' in a JBrowse custom linear genome view.
#'
#' @param data the URL or file path to the BAM/CRAM alignments
#' @param assembly_name the name of the assembly to display the alignments for
#'
#' @return
#' @export
#'
#' @examples
#' track_alignments("alignments.bam", "hg19")
#' track_alignments("alignments.cram", "hg19")
track_alignments <- function(data, assembly_name) {
  # print("It's an alignments track!")
  type <- "AlignmentsTrack"
  name <- get_name(data)
  track_id <- stringr::str_c(assembly_name, "_", name)
  adapter <- get_alignment_adapter(data)

  # return the stringified JSON of track config
  if (stringr::str_ends(data, ".bam")) {
    as.character(
      stringr::str_glue(
        "{{",
          '"type": "{type}", ',
          '"name": "{name}", ',
          '"assemblyNames": ["{assembly_name}"], ',
          '"trackId": "{track_id}", ',
          "{adapter} ",
        "}}"
      )
    )
  }
}

get_alignment_adapter <- function(data) {
  if (stringr::str_ends(data, ".bam")) {
    index <- stringr::str_c(data, ".bai")
    as.character(
      stringr::str_glue(
        '"adapter": {{ ',
          '"type": "BamAdapter", ',
          '"bamLocation": {{ ',
          '"uri": "{data}" ',
          "}}, ",
          '"index": {{ "location": {{ "uri": "{index}" }} }} ',
        "}}"
      )
    )
  } else if (stringr::str_ends(data, ".cram")) {
    index <- stringr::str_c(data, ".crai")
    as.character(
      stringr::str_glue(
        '"adapter": {{ ',
          '"type": "CramAdapter", ',
          '"cramLocation": {{ ',
          '"uri": "{data}" ',
          "}}, ",
          '"craiLocation": {{ "uri": "{index}" }} ',
        "}}"
      )
    )
  } else {
    stop("alignment data must be either BAM or CRAM")
  }
}

# Interface ---------------------------------------------------------------

# I actually probably want to expose a function per type of track.

# The supported tracks are:

# 'AlignmentsTrack'
# 'PileupTrack'
# 'SNPCoverageTrack'
# 'VariantTrack'
# 'WiggleTrack'

# and then I want a tracks() function, that takes an arbitrary number
# of tracks, and glues them into a string with [ at the beginning and ]
# at the end, so that it will be the array of tracks in the config
