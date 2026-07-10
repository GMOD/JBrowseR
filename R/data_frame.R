#' Build a track from an R data frame
#'
#' Turns a data frame of features into an in-browser track (a
#' `FromConfigAdapter`), no files or web server required. This is the natural
#' way to view results you computed in R — peaks, windows, hits — directly on
#' the genome.
#'
#' @param data A data frame with columns `chrom`, `start`, `end`, `name`. An
#'   optional `score` column makes it a quantitative track; any `additional`
#'   column is attached to each feature.
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
      sprintf(
        "`data` is missing required column(s): %s",
        paste(missing, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  has_score <- "score" %in% colnames(data)
  has_additional <- "additional" %in% colnames(data)
  features <- lapply(seq_len(nrow(data)), function(i) {
    feature <- list(
      refName = as.character(data$chrom[i]),
      start = data$start[i],
      end = data$end[i],
      uniqueId = paste0(name, "-", i),
      name = as.character(data$name[i]),
      type = ""
    )
    if (has_score) {
      feature$score <- data$score[i]
    }
    if (has_additional) {
      feature$additional <- as.character(data$additional[i])
    }
    feature
  })

  out <- list(
    type = if (has_score) "QuantitativeTrack" else "FeatureTrack",
    trackId = if (is.null(assembly_name)) name else paste0(assembly_name, "_", name),
    name = name,
    adapter = list(type = "FromConfigAdapter", features = features)
  )
  if (!is.null(assembly_name)) {
    out$assemblyNames <- list(assembly_name)
  }
  extra <- list(...)
  if (length(extra) > 0) {
    out <- utils::modifyList(out, extra)
  }
  out
}
