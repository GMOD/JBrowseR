#' Build a custom color theme
#'
#' Creates a theme config with up to four palette colors. Pass the result as
#' `theme` to [JBrowseR()]. See
#' \url{https://jbrowse.org/jb2/docs/config_guide#configuring-the-theme}.
#'
#' @param primary the primary palette color (hex)
#' @param secondary the secondary palette color (hex)
#' @param tertiary the tertiary palette color (hex)
#' @param quaternary the quaternary palette color (hex)
#'
#' @return a theme config list
#' @export
#'
#' @examples
#' theme("#311b92", "#0097a7")
theme <- function(primary, secondary = NULL, tertiary = NULL,
                  quaternary = NULL) {
  colors <- drop_null(list(
    primary = primary,
    secondary = secondary,
    tertiary = tertiary,
    quaternary = quaternary
  ))
  list(palette = lapply(colors, \(color) list(main = color)))
}
