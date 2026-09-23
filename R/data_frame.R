#' Build a track from an R data frame
#'
#' Turns a data frame of features into an in-browser track (a
#' `FromConfigAdapter`), no files or web server required. This is the natural
#' way to view results you computed in R — peaks, windows, hits — directly on
#' the genome.
#'
#' @param data A data frame with columns `chrom` (or `chr`, or `refName`),
#'   `start` and `end` (0-based, half-open). An optional `score` column makes it
#'   a quantitative track; every other column rides along as a feature
#'   attribute, shown in the feature details and readable by a display's
#'   encoding.
#' @param name Track display name.
#' @param assembly_name Assembly the track belongs to. Usually left `NULL` —
#'   [JBrowseR()] backfills it from the loaded assembly.
#' @param ... Extra config merged into the track. A `displays` list plots the
#'   columns the way a grammar of graphics does: a `LinearMarkDisplay` maps a
#'   column to `y` and another to a colour scale.
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
#'
#' # a point per row at its log2 fold-change, coloured by call
#' de <- data.frame(
#'   chrom = "7", start = c(1e6, 2e6), end = c(1e6, 2e6) + 6000,
#'   log2fc = c(2.1, -1.7), sig = c("up", "down")
#' )
#' track_data_frame(de, "de", displays = list(list(
#'   type = "LinearMarkDisplay",
#'   marks = list(list(
#'     shape = "point",
#'     encoding = list(y = "log2fc", color = list(field = "sig", scale = "categorical"))
#'   ))
#' )))
track_data_frame <- function(data, name, assembly_name = NULL, ...) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame", call. = FALSE)
  }
  ref <- intersect(c("refName", "chrom", "chr"), colnames(data))[1]
  missing <- c(
    if (is.na(ref)) "chrom",
    setdiff(c("start", "end"), colnames(data))
  )
  if (length(missing) > 0) {
    stop(
      "`data` is missing required column(s): ", paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  columns <- as.list(data)
  names(columns)[names(columns) == ref] <- "refName"
  features <- lapply(seq_len(nrow(data)), function(i) {
    c(lapply(columns, `[[`, i), uniqueId = paste0(name, "-", i))
  })
  out <- list(
    type = if ("score" %in% colnames(data)) "QuantitativeTrack" else "FeatureTrack",
    trackId = paste(c(assembly_name, name), collapse = "_"),
    name = name,
    assemblyNames = if (!is.null(assembly_name)) as.list(assembly_name),
    adapter = list(type = "FromConfigAdapter", features = features)
  )
  utils::modifyList(drop_null(out), list(...))
}
