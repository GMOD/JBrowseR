#' Move a rendered browser without rebuilding it
#'
#' Navigates a browser that is already on the page, without a Shiny round-trip
#' through `renderJBrowseR()` — and without the loop that reading
#' `input$<outputId>_location` in the reactive feeding it would build.
#'
#' ```r
#' output$browser <- renderJBrowseR(JBrowseR("hg38", location = "BRCA1"))
#'
#' observeEvent(input$gene, {
#'   update_location("browser", input$gene)
#' })
#' ```
#'
#' Navigation is the only command, and there is deliberately no R function per
#' thing a browser can do. Re-rendering the widget already reconciles a changed
#' `tracks`, `location` or `local_files` into the browser on the page rather
#' than rebuilding it, so a `renderJBrowseR()` driven by a reactive keeps the
#' user's zoom and track order too. What this adds is the direction: a server
#' that navigates in an `observeEvent()` never re-runs the render expression, so
#' reading `input$<outputId>_location` there is not circular.
#'
#' [JBrowseRApp()] cannot be moved this way: it holds any number of views, and
#' which one a location is meant for is not part of its interface.
#'
#' @param outputId The id of the browser to move, the same one passed to
#'   [JBrowseROutput()]. Inside a Shiny module, pass the bare id, as you would
#'   to `output$`.
#' @param location A region string (`"chr1:1-1000"`) or, when the assembly hub
#'   provides a gene-name search index, a gene name (`"BRCA1"`) — the same
#'   vocabulary [JBrowseR()]'s `location` takes, and the same string
#'   `input$<outputId>_location` reports back.
#' @param session The Shiny session, defaulting to the current one.
#'
#' @return `outputId`, invisibly.
#'
#' @export
update_location <- function(outputId, location, session = shiny_session()) {
  stopifnot(is.character(location), length(location) == 1)
  if (is.null(session)) {
    stop(
      "update_location() must be called from inside a Shiny server function",
      call. = FALSE
    )
  }
  session$sendCustomMessage("jbrowser-call", list(
    id = namespaced(outputId, session),
    method = "update",
    args = list(location = location)
  ))
  invisible(outputId)
}

# shiny is a Suggests: the package renders in an Rmd or at the console without
# it, and only this needs it. Reached through requireNamespace so R CMD check
# does not see an unconditional call into a suggested package.
shiny_session <- function() {
  if (requireNamespace("shiny", quietly = TRUE)) {
    shiny::getDefaultReactiveDomain()
  } else {
    NULL
  }
}

# Inside a module the caller passes the bare id, the way they write `output$x`,
# so the namespace is applied here. An already-namespaced id is left alone
# rather than prefixed twice: passing `ns("x")` is the natural mistake, and the
# double-prefixed call would name no widget and be silently ignored.
namespaced <- function(outputId, session) {
  ns <- session$ns
  if (is.null(ns)) {
    return(outputId)
  }
  prefix <- ns("")
  if (!nzchar(prefix) || startsWith(outputId, prefix)) {
    outputId
  } else {
    ns(outputId)
  }
}
