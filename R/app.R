#' Embed the full JBrowse 2 app (multiple views of any type)
#'
#' Where [JBrowseR()] shows a single linear genome view, `JBrowseRApp()` drives
#' the whole app engine, so `views` can mix a linear view, a synteny view, a
#' dotplot, and more.
#'
#' Each `views` entry is a `list(type = ..., init = ...)` spec — the same
#' vocabulary JBrowse Web serializes into its
#' \href{https://jbrowse.org/jb2/docs/urlparams/}{`?session=spec-…` URLs}, and
#' the `init` fields are that view's own
#' \href{https://jbrowse.org/jb2/docs/models/}{state-model options}. There is no
#' R constructor for it, so every view type JBrowse has — including one a
#' runtime `plugins` entry registers — opens with nothing added to this package.
#'
#' A comparative view's panels are `list(assembly = , loc = )`, one per side.
#' Note that fields JBrowse reads as arrays need `list()`, since a length-1
#' vector would serialize as a JSON scalar.
#'
#' @param assemblies A list of assembly configs — `list(name = , uri = )` each.
#'   A synteny/dotplot view needs two or more.
#' @param tracks A list of full track config lists. A synteny track spans two
#'   assemblies, so it names both in `assemblyNames` and in its adapter.
#' @param views A list of `list(type = , init = )` view specs.
#' @param plugins A list of JBrowse plugin specs (name + url) to load at runtime.
#' @param theme A theme config, the
#'   \href{https://jbrowse.org/jb2/docs/config_guide/#configuring-the-theme}{MUI
#'   palette} JBrowse takes.
#' @param config Escape hatch: a whole JBrowse config forming the payload base
#'   that explicit arguments override — a list, or the path, URL, or JSON text of
#'   a `config.json`.
#' @param width,height,elementId Standard htmlwidget sizing arguments.
#'
#' @return an htmlwidget of the JBrowse 2 app
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
#'     init = list(
#'       views = list(list(assembly = "hg38"), list(assembly = "mm39")),
#'       tracks = list("hg38_mm39")
#'     )
#'   ))
#' )
#' }
JBrowseRApp <- function(assemblies = NULL, tracks = NULL, views = NULL,
                        plugins = NULL, theme = NULL, config = NULL,
                        width = NULL, height = NULL, elementId = NULL) {
  if (is.null(assemblies) && is.null(config)) {
    stop("provide `assemblies` (or a whole `config`)", call. = FALSE)
  }
  create_widget("JBrowseRApp", config, list(
    assemblies = assemblies,
    tracks = tracks,
    views = views,
    plugins = plugins,
    configuration = configuration_from_theme(theme)
  ), width, height, elementId)
}
