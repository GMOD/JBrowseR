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
  palette <- list(primary = list(main = primary))
  if (!is.null(secondary)) {
    palette$secondary <- list(main = secondary)
  }
  if (!is.null(tertiary)) {
    palette$tertiary <- list(main = tertiary)
  }
  if (!is.null(quaternary)) {
    palette$quaternary <- list(main = quaternary)
  }
  list(palette = palette)
}
