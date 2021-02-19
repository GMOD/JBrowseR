#' Create a theme for a custom JBrowse 2 view
#'
#' Creates the necessary configuration string
#' for a custom theme palette for your browser.
#' Accepts up to four hexadecimal colors. For more
#' information on how JBrowse 2 custom themes work,
#' visit \url{https://jbrowse.org/jb2/docs/config_guide#configuring-the-theme}
#'
#' @param primary the primary color of your custom palette
#' @param secondary the secondary color of your custom palette
#' @param tertiary the tertiary color of your custom palette
#' @param quaternary the quaternary color of your custom palette
#'
#' @return a character vector of stringified theme JSON configuration
#'   to configure a custom color palette for the browser
#'
#' @export
#'
#' @examples
#' theme("#311b92")
#' theme("#311b92", "#0097a7")
#' theme("#311b92", "#0097a7", "#f57c00")
#' theme("#311b92", "#0097a7", "#f57c00", "#d50000")
theme <- function(primary, secondary = NULL, tertiary = NULL, quaternary = NULL) {
  if (is.null(secondary)) {
    secondary_string <- ""
  } else {
    secondary_string <- stringr::str_glue(
      ', "secondary": {{ "main": "{secondary}" }}'
    )
  }

  if (is.null(tertiary)) {
    tertiary_string <- ""
  } else {
    tertiary_string <- stringr::str_glue(
      ', "tertiary": {{ "main": "{tertiary}" }}'
    )
  }

  if (is.null(quaternary)) {
    quaternary_string <- ""
  } else {
    quaternary_string <- stringr::str_glue(
      ', "quaternary": {{ "main": "{quaternary}" }}'
    )
  }

  as.character(
    stringr::str_glue(
      "{{ ",
      '"palette": {{ ',
      '"primary": {{ "main": "{primary}" }}',
      "{secondary_string}",
      "{tertiary_string}",
      "{quaternary_string}",
      "}}",
      "}}"
    )
  )
}
