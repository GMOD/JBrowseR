#' Embed a JBrowse 2 linear genome view
#'
#' Renders an interactive, GPU-accelerated JBrowse 2 linear genome view as an
#' htmlwidget for R Markdown documents, Shiny apps, or the R console.
#'
#' Every named argument in `...` is an option of JBrowse's
#' \href{https://jbrowse.org/jb2/docs/embedded_components/}{`createLinearGenomeView`},
#' sent verbatim under JBrowse's own camelCase name: `assembly`, `tracks`,
#' `location`, `session`, `aggregateTextSearchAdapters`, `internetAccounts`,
#' `plugins`, `configuration`, and whatever JBrowse adds next. This package
#' names none of them, so a whole options object is
#' `do.call(JBrowseR, jsonlite::read_json("options.json"))`.
#'
#' `assembly` takes a hub name (`"hg38"`, a GenArk accession), a sequence-file
#' URL, or an assembly config. A `tracks` entry takes a bare data-file URL, a
#' `list(uri = )`, a [track_data_frame()] result, or a full track config.
#' `plugins` entries are `list(name = , url = )`.
#'
#' A length-1 vector serializes to a JSON scalar, so fields JBrowse reads as
#' arrays take `list()`: `assemblyNames = list("hg38")`.
#'
#' @param ... `createLinearGenomeView` options, each named.
#' @param local_files Files on this machine to open without a web server: a
#'   path, a vector of paths, or a list mixing paths with `raw` vectors. Each
#'   registers under its basename (or its list name), and a track refers to that
#'   name as if it were a URL. A sibling index (`.tbi`, `.csi`, `.bai`, `.crai`,
#'   `.fai`, `.gzi`) next to a path comes along.
#' @param width,height,elementId Standard htmlwidget sizing arguments.
#'
#' @return an htmlwidget
#'
#' @import htmlwidgets
#' @export
#'
#' @examples
#' JBrowseR(assembly = "hg38", location = "BRCA1")
JBrowseR <- function(..., local_files = NULL, width = NULL, height = NULL,
                     elementId = NULL) {
  create_widget("JBrowseR", list(...), local_files, width, height, elementId)
}

#' Shiny bindings for JBrowseR
#'
#' Output and render functions for [JBrowseR()] in Shiny apps and interactive
#' Rmd documents.
#'
#' The widget reports three inputs, namespaced by output id:
#' `input[[paste0(outputId, "_selected_feature")]]` is the clicked feature,
#' `_location` the visible region as the location box prints it (thousands
#' separators included), and `_session` the layout in the shape `session =`
#' takes. Each settles after a gesture rather than firing per frame.
#'
#' A re-render whose options differ only in `tracks`, `location` or
#' `local_files` is applied to the browser on the page, keeping the user's zoom
#' and track order; any other changed option builds a new browser. Reading
#' `_location` or `_session` in the reactive that feeds `renderJBrowseR()` builds
#' a loop: navigate from an observer with [update_jbrowse()] instead.
#'
#' @param outputId output variable to read from
#' @param width,height a valid CSS unit, or a number coerced to pixels
#' @param expr An expression that generates a JBrowseR
#' @param env The environment in which to evaluate `expr`.
#' @param quoted Is `expr` a quoted expression (with `quote()`)?
#'
#' @name JBrowseR-shiny
#'
#' @return the Shiny UI bindings for a JBrowseR htmlwidget
#'
#' @export
JBrowseROutput <- function(outputId, width = "100%", height = "400px") {
  htmlwidgets::shinyWidgetOutput(outputId, "JBrowseR", width, height, package = "JBrowseR")
}

#' @rdname JBrowseR-shiny
#'
#' @return the Shiny server bindings for a JBrowseR htmlwidget
#'
#' @export
renderJBrowseR <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) {
    expr <- substitute(expr)
  }
  htmlwidgets::shinyRenderWidget(expr, JBrowseROutput, env, quoted = TRUE)
}
