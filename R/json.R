#' Read in a JBrowse 2 JSON configuration file
#'
#' Reads in a JSON file with values for configuring
#' your browser. Looks for assembly, tracks, defaultSession,
#' and theme. Only assembly is explicitly required for a
#' working browser.
#'
#' Note: this is the most advanced API. It offers full control
#' to do anything possible in JavaScript with an embedded JBrowse 2
#' React component, but comes with a steeper learning curve. For
#' more details on JBrowse 2 configuration, visit:
#' \url{https://jbrowse.org/jb2/docs/config_guide}
#'
#' An example JSON config is provided with this package
#'
#' @param file the file path or URL to a JBrowse 2 configuration
#'
#' @return
#' @export
#'
#' @examples
#' \dontrun{json_config("./config.json")}
json_config <- function(file) {
  readr::read_file(file)
}
