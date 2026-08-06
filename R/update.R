#' Move a rendered browser without rebuilding it
#'
#' Navigates a browser that is already on the page. This is how a Shiny app
#' should move the view: the alternative is putting a reactive into
#' `renderJBrowseR()`, which rebuilds the whole browser, refetching its tracks
#' and discarding the user's zoom, track order, scroll position and feature
#' selection.
#'
#' ```r
#' output$browser <- renderJBrowseR(JBrowseR("hg38", location = "BRCA1"))
#'
#' observeEvent(input$gene, {
#'   update_location("browser", input$gene)
#' })
#' ```
#'
#' It also settles the loop `input$<outputId>_location` otherwise creates.
#' Reading that input in a reactive that feeds `renderJBrowseR()` is circular,
#' because the rebuild resets the view; reading it in an `observeEvent()` that
#' calls `update_location()` is not.
#'
#' Navigation is the only command, and there is deliberately no R function per
#' thing a browser can do. A browser's tracks, assembly and session can also be
#' swapped live, but each has to answer what it does to a track the user opened
#' by hand or a layout they rearranged — and "rebuild" is a defensible answer to
#' those, which is what re-rendering the widget already does. Moving the locus
#' has one meaning and is the interaction that repeats.
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
    method = "setLocation",
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
