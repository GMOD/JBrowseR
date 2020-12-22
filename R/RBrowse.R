#' <Add Title>
#'
#' <Add Description>
#'
#' @import htmlwidgets
#'
#' @export
RBrowse <- function(location, width = NULL, height = NULL, elementId = NULL) {

  # describe a React component to send to the browser for rendering.
  # TODO: get the location passed to actually be used by widget
  component <- reactR::component("ViewHg38", list(location = location))

  # create widget
  htmlwidgets::createWidget(
    name = 'RBrowse',
    reactR::reactMarkup(component),
    width = width,
    height = height,
    package = 'RBrowse',
    elementId = elementId
  )
}

#' Shiny bindings for RBrowse
#'
#' Output and render functions for using RBrowse within Shiny
#' applications and interactive Rmd documents.
#'
#' @param outputId output variable to read from
#' @param width,height Must be a valid CSS unit (like \code{'100\%%'},
#'   \code{'400px'}, \code{'auto'}) or a number, which will be coerced to a
#'   string and have \code{'px'} appended.
#' @param expr An expression that generates a RBrowse
#' @param env The environment in which to evaluate \code{expr}.
#' @param quoted Is \code{expr} a quoted expression (with \code{quote()})? This
#'   is useful if you want to save an expression in a variable.
#'
#' @name RBrowse-shiny
#'
#' @export
RBrowseOutput <- function(outputId, width = '100%', height = '400px'){
  htmlwidgets::shinyWidgetOutput(outputId, 'RBrowse', width, height, package = 'RBrowse')
}

#' @rdname RBrowse-shiny
#' @export
renderRBrowse <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) { expr <- substitute(expr) } # force quoted
  htmlwidgets::shinyRenderWidget(expr, RBrowseOutput, env, quoted = TRUE)
}

#' Called by HTMLWidgets to produce the widget's root element.
#' @rdname RBrowse-shiny
RBrowse_html <- function(id, style, class, ...) {
  htmltools::tagList(
    # Necessary for RStudio viewer version < 1.2
    reactR::html_dependency_corejs(),
    reactR::html_dependency_react(),
    reactR::html_dependency_reacttools(),
    htmltools::tags$div(id = id, class = class, style = style)
  )
}
