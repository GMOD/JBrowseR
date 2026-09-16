library(shiny)
library(JBrowseR)
library(bslib)

# JBrowse 2 plugins extend the browser with new track types, adapters, and
# behaviors. This config.json loads the ModifyHTTPHeaders plugin (useful for
# authenticated data sources) and sets the `internetAccounts` it reads, which
# have no R argument, alongside an hg19 gene track.

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
