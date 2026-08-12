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
#' @param assemblies A list of assemblies. Each entry is a config —
#'   `list(name = , uri = )` — or a shorthand string: a hub name (`"hg38"`,
#'   `"GCF_..."`) or a sequence-file URL, the same shorthands [JBrowseR()]
#'   accepts. A synteny/dotplot view needs two or more.
#' @param tracks A list of full track config lists. A synteny track spans two
#'   assemblies, so it names both in `assemblyNames` and in its adapter.
#' @param views A list of `list(type = , init = )` view specs.
#' @param session A previously saved session to restore instead of `views` —
#'   the value a running app reported as
#'   `input[[paste0(outputId, "_session")]]`. Unlike `views`, which describes
#'   what to open, this carries the state the user built: navigation, open
#'   tracks, per-display settings, widgets. `views` still describes what
#'   File → New session returns to.
#' @param local_files Files on this machine to open without a web server: a path,
#'   a vector of paths, or a list mixing paths with `raw` vectors of bytes you
#'   already hold. Each registers under its basename (or its list name), and a
#'   track then refers to that name as if it were a URL — see the "Hosting data"
#'   vignette. A conventional sibling index (`.tbi`, `.csi`, `.bai`, `.crai`,
#'   `.fai`, `.gzi`) next to a path is picked up too, so an indexed file stays
#'   indexed and JBrowse reads only the region on screen.
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
#' # assemblies also accept hub-name shorthands: assemblies = list("hg38", "mm39")
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
                        session = NULL, local_files = NULL, plugins = NULL,
                        theme = NULL, config = NULL, width = NULL,
                        height = NULL, elementId = NULL) {
  if (is.null(assemblies) && is.null(config)) {
    stop("provide `assemblies` (or a whole `config`)", call. = FALSE)
  }
  create_widget("JBrowseRApp", config, list(
    assemblies = assemblies,
    tracks = tracks,
    views = views,
    session = session,
    localFiles = read_local_files(local_files),
    plugins = plugins,
    configuration = configuration_from_theme(theme)
  ), width, height, elementId)
}

#' Shiny bindings for JBrowseRApp
#'
#' Output and render functions for using [JBrowseRApp()] within Shiny
#' applications and interactive Rmd documents. These are separate from
#' [JBrowseROutput()] because the app is a separate widget with its own
#' JavaScript bundle: htmlwidgets dispatches on the output element's class, so
#' rendering a `JBrowseRApp()` into a `JBrowseROutput()` loads the single-view
#' bundle and fails to build.
#'
#' Whatever the user does to the layout — navigating, opening tracks, adding or
#' rearranging views — is reported as
#' `input[[paste0(outputId, "_session")]]`, in the same shape `session =`
#' takes. So "save this layout" is storing that value, and reopening it is
#' passing it back:
#'
#' ```r
#' output$app <- renderJBrowseRApp(JBrowseRApp(assemblies, views = saved()))
#' observeEvent(input$save, { saved(input$app_session) })
#' ```
#'
#' It rides a coarse signal — which views exist, what each has open, and where
#' each is looking — so it settles after a gesture instead of firing per frame.
#' Reading it in the reactive that feeds `renderJBrowseRApp()` builds a loop:
#' store it on an event, don't wire it straight through.
#'
#' Two narrower read-backs sit beside it, under the same names
#' [JBrowseROutput()] uses. `input[[paste0(outputId, "_selected_feature")]]` is
#' the feature the user last clicked, in any view.
#' `input[[paste0(outputId, "_location")]]` is where the app is looking — a
#' *list*, one entry per open view, because this widget holds any number of
#' them where [JBrowseR()] holds one and reports a single string. A comparative
#' view contributes a character vector, one per panel, since a synteny view has
#' no single visible region. The entries are in view order, which changes when
#' the user adds or closes a view, so read `_session` instead when you need to
#' know which view a region belongs to.
#'
#' @param outputId output variable to read from
#' @param width Must be a valid CSS unit or a number, which will be coerced to a string and have \code{'px'} appended.
#' @param height Must be a valid CSS unit or a number, which will be coerced to a string and have \code{'px'} appended.
#' @param expr An expression that generates a JBrowseRApp
#' @param env The environment in which to evaluate \code{expr}.
#' @param quoted Is \code{expr} a quoted expression (with \code{quote()})? This
#'   is useful if you want to save an expression in a variable.
#'
#' @name JBrowseRApp-shiny
#'
#' @return the Shiny UI bindings for a JBrowseRApp htmlwidget
#'
#' @export
JBrowseRAppOutput <- function(outputId, width = "100%", height = "400px") {
  htmlwidgets::shinyWidgetOutput(
    outputId, "JBrowseRApp", width, height,
    package = "JBrowseR"
  )
}

#' @rdname JBrowseRApp-shiny
#'
#' @return the Shiny server bindings for a JBrowseRApp htmlwidget
#'
#' @export
renderJBrowseRApp <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) {
    expr <- substitute(expr)
  } # force quoted
  htmlwidgets::shinyRenderWidget(expr, JBrowseRAppOutput, env, quoted = TRUE)
}
