#' Change options of a rendered browser
#'
#' Sends option changes to a [JBrowseR()] or [JBrowseRApp()] already on the
#' page, without re-running its render expression. The changes are named the
#' way the widget's own options are.
#'
#' ```r
#' observeEvent(input$gene, update_jbrowse("browser", location = input$gene))
#' ```
#'
#' A [JBrowseR()] applies `tracks` and `location` in place and a [JBrowseRApp()]
#' applies `session` in place; any other option builds a new browser from the
#' rendered options plus the changes. A later re-render compares against what
#' it rendered last, so a change sent here survives a re-render that does not
#' restate that option.
#'
#' @param outputId The browser's output id. Inside a Shiny module, pass the bare
#'   id, as you would to `output$`.
#' @param ... Options to change, each named.
#' @param domain The Shiny session, defaulting to the current one. Not named
#'   `session`, which is an option.
#'
#' @return `outputId`, invisibly.
#'
#' @export
update_jbrowse <- function(outputId, ..., domain = shiny_domain()) {
  if (is.null(domain)) {
    stop("update_jbrowse() must be called from inside a Shiny server function", call. = FALSE)
  }
  domain$sendCustomMessage("jbrowser-update", list(
    id = namespaced(outputId, domain),
    options = named_options(list(...))
  ))
  invisible(outputId)
}

shiny_domain <- function() {
  if (requireNamespace("shiny", quietly = TRUE)) {
    shiny::getDefaultReactiveDomain()
  }
}

# an id already namespaced is left alone: ns("x") is the natural mistake, and
# prefixing it twice would name no widget
namespaced <- function(outputId, domain) {
  prefix <- if (is.null(domain$ns)) "" else domain$ns("")
  if (!nzchar(prefix) || startsWith(outputId, prefix)) {
    outputId
  } else {
    domain$ns(outputId)
  }
}
