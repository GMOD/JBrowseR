library(shiny)
library(JBrowseR)
library(bslib)

# config.json holds JBrowseR()'s options (`assembly`, `tracks`, `location`, ...),
# so the browser lives in a file rather than in R. It is not a JBrowse Web
# config.json, which lists `assemblies` and opens a `defaultSession`.

ui <- fluidPage(
  theme = bs_theme(version = 5),
  titlePanel("JBrowseR: load a config.json"),
  JBrowseROutput("widgetOutput")
)

server <- function(input, output, session) {
  output$widgetOutput <- renderJBrowseR(
    do.call(JBrowseR, jsonlite::read_json("config.json"))
  )
}

shinyApp(ui, server)
