#' Build a track from an R data frame
#'
#' Turns a data frame of features into an in-browser track (a
#' `FromConfigAdapter`), no files or web server required. This is the natural
#' way to view results you computed in R — peaks, windows, hits — directly on
#' the genome.
#'
#' @param data A data frame with columns `chrom`, `start`, `end`, `name`. An
#'   optional `score` column makes it a quantitative track; every other column
#'   rides along as a feature attribute, shown in the feature details.
#' @param name Track display name.
#' @param assembly_name Assembly the track belongs to. Usually left `NULL` —
#'   [JBrowseR()] backfills it from the loaded assembly.
#' @param ... Extra config merged into the track.
#'
#' @return a track config list
#' @export
#'
#' @examples
#' df <- data.frame(
#'   chrom = c("1", "2"),
#'   start = c(123, 456),
#'   end = c(789, 101112),
#'   name = c("feature1", "feature2")
#' )
#' track_data_frame(df, "my_features")
track_data_frame <- function(data, name, assembly_name = NULL, ...) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame", call. = FALSE)
  }
  missing <- setdiff(c("chrom", "start", "end", "name"), colnames(data))
  if (length(missing) > 0) {
    stop(
      "`data` is missing required column(s): ", paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  colnames(data)[colnames(data) == "chrom"] <- "refName"
  features <- lapply(seq_len(nrow(data)), \(i) {
    c(as.list(data[i, ]), uniqueId = paste0(name, "-", i), type = "")
  })
  out <- list(
    type = if ("score" %in% colnames(data)) "QuantitativeTrack" else "FeatureTrack",
    trackId = paste(c(assembly_name, name), collapse = "_"),
    name = name,
    assemblyNames = as_json_array(assembly_name),
    adapter = list(type = "FromConfigAdapter", features = features)
  )
  utils::modifyList(drop_null(out), list(...))
}
