`%||%` <- function(a, b) {
  if (is.null(a)) b else a
}

drop_null <- function(x) {
  x[!vapply(x, is.null, logical(1))]
}

# a named list, so an empty one serializes as {} rather than []
named_options <- function(options) {
  keys <- names(options) %||% rep("", length(options))
  if (!all(nzchar(keys))) {
    stop("every option is named, e.g. `assembly = \"hg38\"`", call. = FALSE)
  }
  options <- drop_null(options)
  names(options) <- names(options) %||% character()
  options
}

create_widget <- function(name, options, local_files, width, height, elementId) {
  options <- named_options(options)
  options$localFiles <- read_local_files(local_files)
  htmlwidgets::createWidget(
    name = name,
    x = options,
    width = width,
    height = height,
    package = "JBrowseR",
    elementId = elementId,
    sizingPolicy = htmlwidgets::sizingPolicy(
      defaultWidth = "100%",
      viewer.fill = TRUE,
      browser.fill = TRUE
    )
  )
}
