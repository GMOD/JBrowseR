library(shiny)
library(JBrowseR)
library(bslib)

# JBrowse 2 plugins extend the browser with new track types, adapters, and
# behaviors. Plugins are declared in a config, so the config= escape hatch is how
# you load them. This config.json pulls in the ModifyHTTPHeaders plugin (useful
# for authenticated data sources) alongside an hg19 gene track.

ui <- fluidPage(
  theme = bs_theme(version = 5),
  titlePanel("JBrowseR: loading a JBrowse 2 plugin"),
  JBrowseROutput("browserOutput")
)

server <- function(input, output, session) {
  output$browserOutput <- renderJBrowseR(JBrowseR(
    config = "./config.json",
    location = "1:20,000,000-20,500,000"
  ))
}

shinyApp(ui, server)
