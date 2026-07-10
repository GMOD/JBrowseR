library(shiny)
library(JBrowseR)
library(bslib)

# The escape hatch: hand JBrowseR a whole JBrowse 2 config.json for full control.
# The same file works in the JBrowse web app and desktop.

ui <- fluidPage(
  theme = bs_theme(version = 5),
  titlePanel("JBrowseR: load a config.json"),
  JBrowseROutput("widgetOutput")
)

server <- function(input, output, session) {
  output$widgetOutput <- renderJBrowseR(JBrowseR(
    config = json_config("./config.json"),
    location = "10:29,838,737..29,838,819"
  ))
}

shinyApp(ui, server)
