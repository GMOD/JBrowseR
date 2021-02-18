#' R interface to JBrowse 2 genome browser
#'
#' Embed a JBrowse 2 linear genome view in your Shiny app,
#' Rmd document, or interactive R console.
#'
#' @param view Which JBrowse 2 view to use. View, JsonView, ViewHg19, ViewHg38
#' @param ... The parameters passed on to the view
#' @param width The width of the htmlwidget
#' @param height The height of the htmlwidget
#' @param elementId The elementId of the htmlwidget
#'
#' @import htmlwidgets
#' @export
JBrowseR <- function(view, ..., width = NULL, height = NULL, elementId = NULL) {

  # describe a React component to send to the browser for rendering.
  component <- reactR::component(view, list(...))

  # create widget
  htmlwidgets::createWidget(
    name = "JBrowseR",
    reactR::reactMarkup(component),
    width = width,
    height = height,
    package = "JBrowseR",
    elementId = elementId
  )
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
#' @export
JBrowseROutput <- function(outputId, width = "100%", height = "400px") {
  htmlwidgets::shinyWidgetOutput(outputId, "JBrowseR", width, height, package = "JBrowseR")
}

#' @rdname JBrowseR-shiny
#' @export
renderJBrowseR <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) {
    expr <- substitute(expr)
  } # force quoted
  htmlwidgets::shinyRenderWidget(expr, JBrowseROutput, env, quoted = TRUE)
}

#' Called by HTMLWidgets to produce the widget's root element.
#'
#' @param id htmltools id
#' @param style htmltools style
#' @param class htmltools class
#' @param ... Additional arguments passed on
#'
#' @rdname JBrowseR-shiny
JBrowseR_html <- function(id, style, class, ...) {
  htmltools::tagList(
    # Necessary for RStudio viewer version < 1.2
    reactR::html_dependency_corejs(),
    reactR::html_dependency_react(),
    reactR::html_dependency_reacttools(),
    htmltools::tags$div(id = id, class = class, style = style)
  )
}
