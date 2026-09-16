#' Embed the full JBrowse 2 app (multiple views of any type)
#'
#' Where [JBrowseR()] shows one linear genome view, `JBrowseRApp()` runs the
#' whole app, so `views` can mix a linear view, a synteny view, a dotplot, and
#' more.
#'
#' Every named argument in `...` is an option of JBrowse's
#' \href{https://jbrowse.org/jb2/docs/embedded_components/}{`createApp`}, sent
#' verbatim under JBrowse's own camelCase name: `assemblies`, `tracks`, `views`,
#' `session`, `connections`, `internetAccounts`, `aggregateTextSearchAdapters`,
#' `configuration`, `plugins`, and whatever JBrowse adds next. A whole options
#' object is `do.call(JBrowseRApp, jsonlite::read_json("options.json"))`.
#'
#' A `views` entry is `list(type = , ...)` with the view's settings beside
#' `type`, the object a `config.json`'s `defaultSession.views` holds. An
#' `assemblies` entry may be a hub name or sequence-file URL, as
#' [JBrowseR()]'s `assembly` takes.
#'
#' @inheritParams JBrowseR
#' @param ... `createApp` options, each named.
#'
#' @return an htmlwidget
#'
#' @import htmlwidgets
#' @export
#'
#' @examples
#' \dontrun{
#' JBrowseRApp(
#'   assemblies = list(
#'     list(name = "hg38", uri = hg38_fa),
#'     list(name = "mm39", uri = mm39_fa)
#'   ),
#'   tracks = list(list(
#'     type = "SyntenyTrack",
#'     trackId = "hg38_mm39",
#'     name = "hg38 vs mm39",
#'     assemblyNames = list("hg38", "mm39"),
#'     adapter = list(
#'       type = "PAFAdapter",
#'       targetAssembly = "hg38",
#'       queryAssembly = "mm39",
#'       uri = paf_url
#'     )
#'   )),
#'   views = list(list(
#'     type = "LinearSyntenyView",
#'     views = list(list(assembly = "hg38"), list(assembly = "mm39")),
#'     tracks = list("hg38_mm39")
#'   ))
#' )
#' }
JBrowseRApp <- function(..., local_files = NULL, width = NULL, height = NULL,
                        elementId = NULL) {
  create_widget("JBrowseRApp", list(...), local_files, width, height, elementId)
}

#' Shiny bindings for JBrowseRApp
#'
#' Output and render functions for [JBrowseRApp()]. The app is a separate
#' widget with its own bundle, so it cannot render into a [JBrowseROutput()].
#'
#' The app reports `input[[paste0(outputId, "_session")]]` in the shape
#' `session =` takes, `_selected_feature` for the clicked feature, and
#' `_location` as a list with one entry per open view. A re-render that changes
#' only `session` restores it in the app on the page; any other changed option
#' builds a new app.
#'
#' @inheritParams JBrowseR-shiny
#' @param expr An expression that generates a JBrowseRApp
#'
#' @name JBrowseRApp-shiny
#'
#' @return the Shiny UI bindings for a JBrowseRApp htmlwidget
#'
#' @export
JBrowseRAppOutput <- function(outputId, width = "100%", height = "400px") {
  htmlwidgets::shinyWidgetOutput(outputId, "JBrowseRApp", width, height, package = "JBrowseR")
}

#' @rdname JBrowseRApp-shiny
#'
#' @return the Shiny server bindings for a JBrowseRApp htmlwidget
#'
#' @export
renderJBrowseRApp <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) {
    expr <- substitute(expr)
  }
  htmlwidgets::shinyRenderWidget(expr, JBrowseRAppOutput, env, quoted = TRUE)
}
