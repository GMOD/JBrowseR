#' Load a whole JBrowse 2 config file
#'
#' Reads a JBrowse 2 JSON config file (or URL) into a string to pass as the
#' `config` argument of [JBrowseR()]. This is the escape hatch for full control
#' — assembly, tracks, defaultSession, theme, plugins — matching the shape of a
#' JBrowse config.json.
#'
#' See \url{https://jbrowse.org/jb2/docs/config_guide}.
#'
#' @param file path or URL to a JBrowse 2 configuration file
#'
#' @return the config file contents as a JSON string
#' @export
#'
#' @examples
#' \dontrun{
#' JBrowseR(config = json_config("./config.json"))
#' }
json_config <- function(file) {
  paste(readLines(file, warn = FALSE), collapse = "\n")
}
