#' Embed a JBrowse 2 linear genome view
#'
#' Renders an interactive, GPU-accelerated JBrowse 2 linear genome view as an
#' htmlwidget for use in R Markdown documents, Shiny apps, or the interactive R
#' console.
#'
#' The API is declarative, and the thing you describe it with is JBrowse's own
#' config: assemblies, tracks and sessions are the same
#' \href{https://jbrowse.org/jb2/docs/config_guide/}{JSON objects} a
#' `config.json` holds, written as R lists. There are deliberately no
#' constructors for them — what you write here is what the config file holds,
#' and nothing in this package has to grow when JBrowse gains a track type, an
#' adapter or a display. The one exception is [track_data_frame()], for the one
#' thing config JSON cannot express: an R data frame.
#'
#' One R-specific trap: a length-1 vector serializes to a JSON scalar, so fields
#' JBrowse reads as arrays (`assemblyNames`, `aliases`) are written with
#' `list()` — `assemblyNames = list("hg38")`, not `"hg38"`.
#'
#' @param assembly A hub name understood by jbrowse.org (e.g. `"hg38"`, `"hg19"`,
#'   or a GenArk accession like `"GCF_000001405.40"`), a sequence-file URL the
#'   view builds an assembly from (`".../hg38.fa.gz"`, `.2bit`), or an assembly
#'   config list — `list(name = , uri = )`, plus `aliases` or `refNameAliases`
#'   when needed.
#' @param tracks A list of track entries: a bare data-file URL, a
#'   `list(uri = )` spec the view expands, a config from [track_data_frame()],
#'   or a full track config. Entries missing `assemblyNames` are backfilled with
#'   the assembly's name by the view.
#' @param location A region string (`"chr1:1-1000"`) or, when the assembly hub
#'   provides a gene-name search index, a gene name (`"BRCA1"`).
#' @param default_session An optional serialized session (advanced); when given
#'   it owns the initial track layout instead of `tracks`.
#' @param text_search One or more aggregate text-search adapter configs (e.g. a
#'   `TrixTextSearchAdapter`), enabling gene-name search.
#' @param theme A theme config, the
#'   \href{https://jbrowse.org/jb2/docs/config_guide/#configuring-the-theme}{MUI
#'   palette} JBrowse takes: `list(palette = list(primary = list(main = )))`.
#' @param plugins A list of JBrowse plugin specs (name + url) to load at runtime.
#' @param config Escape hatch: a whole JBrowse config forming the payload base
#'   that explicit arguments override — a list, or the path, URL, or JSON text of
#'   a `config.json`.
#' @param width,height,elementId Standard htmlwidget sizing arguments.
#'
#' @return an htmlwidget of the JBrowse 2 linear genome view
#'
#' @import htmlwidgets
#' @export
#'
#' @examples
#' # a whole human genome browser in one line (gene search included)
#' JBrowseR("hg38", location = "BRCA1")
JBrowseR <- function(assembly = NULL, tracks = NULL, location = NULL,
                     default_session = NULL, text_search = NULL, theme = NULL,
                     plugins = NULL, config = NULL, width = NULL, height = NULL,
                     elementId = NULL) {
  if (is.null(assembly) && is.null(config)) {
    stop("provide an `assembly` (or a whole `config`)", call. = FALSE)
  }
  create_widget("JBrowseR", config, list(
    assembly = assembly,
    tracks = tracks,
    location = location,
    defaultSession = default_session,
    aggregateTextSearchAdapters = as_adapter_list(text_search),
    configuration = configuration_from_theme(theme),
    plugins = plugins
  ), width, height, elementId)
}

#' Shiny bindings for JBrowseR
#'
#' Output and render functions for using JBrowseR within Shiny
#' applications and interactive Rmd documents.
#'
#' Clicking a feature sets `input[[paste0(outputId, "_selected_feature")]]`,
#' which is namespaced per output and so is safe with several browsers on a
#' page or inside a Shiny module. It also sets the global `input$selectedFeature`
#' for backwards compatibility; prefer the per-output id in new apps.
#'
#' Panning or zooming sets `input[[paste0(outputId, "_location")]]` to the
#' visible region, so the server can recompute for what the user is looking at.
#' It settles after the gesture rather than firing per frame, and there is no
#' global twin — use the namespaced id:
#'
#' ```r
#' output$browser <- renderJBrowseR(JBrowseR("hg38", location = "BRCA1"))
#' output$region <- renderText(input$browser_location)
#' ```
#'
#' The value is the same string the location box displays, which means it is
#' formatted for reading rather than for parsing: coordinates carry thousand
#' separators (`"17:43,044,295..43,125,483"`), and a view showing several
#' regions gives them space-separated. Strip the commas before doing arithmetic
#' with it — `as.numeric(gsub(",", "", x))`. It feeds straight back into
#' `location =` unchanged, though (JBrowse parses what it prints).
#'
#' Note that reading it in a reactive that also feeds `renderJBrowseR()` builds
#' a loop: the widget rebuilds on every change, and a rebuild resets the view.
#' Read it to drive *other* outputs.
#'
#' @param outputId output variable to read from
#' @param width Must be a valid CSS unit or a number, which will be coerced to a string and have \code{'px'} appended.
#' @param height Must be a valid CSS unit or a number, which will be coerced to a string and have \code{'px'} appended.
#' @param expr An expression that generates a JBrowseR
#' @param env The environment in which to evaluate \code{expr}.
#' @param quoted Is \code{expr} a quoted expression (with \code{quote()})? This
#'   is useful if you want to save an expression in a variable.
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
  } # force quoted
  htmlwidgets::shinyRenderWidget(expr, JBrowseROutput, env, quoted = TRUE)
}
