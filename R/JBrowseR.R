#' Embed a JBrowse 2 linear genome view
#'
#' Renders an interactive, GPU-accelerated JBrowse 2 linear genome view as an
#' htmlwidget for use in R Markdown documents, Shiny apps, or the interactive R
#' console.
#'
#' The API is declarative: describe the browser with plain values and the
#' helper constructors ([assembly()], [track()], [tracks()], [text_index()],
#' [theme()]). Nothing is imperative and no JSON strings are assembled by hand.
#'
#' @param assembly A hub name understood by jbrowse.org (e.g. `"hg38"`, `"hg19"`,
#'   or a GenArk accession like `"GCF_000001405.40"`), a sequence-file URL the
#'   view builds an assembly from (`".../hg38.fa.gz"`, `.2bit`), or an assembly
#'   config list from [assembly()] (needed only for aliases or a non-sibling
#'   index).
#' @param tracks A list of track entries: a bare data-file URL, a spec from
#'   [track()] / [track_data_frame()], or a full track config. Entries missing
#'   `assemblyNames` are backfilled with the assembly's name by the view.
#' @param location A region string (`"chr1:1-1000"`) or, when the assembly hub
#'   provides a gene-name search index, a gene name (`"BRCA1"`).
#' @param default_session An optional serialized session (advanced); when given
#'   it owns the initial track layout instead of `tracks`.
#' @param text_search One or more aggregate text-search adapters from
#'   [text_index()], enabling gene-name search.
#' @param theme A theme config from [theme()].
#' @param plugins A list of JBrowse plugin specs (name + url) to load at runtime.
#' @param config Escape hatch: a whole JBrowse config (a list, or a JSON string
#'   from [json_config()]) forming the payload base that explicit arguments
#'   override.
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
