library(shiny)
library(RBrowse)

ui <- fluidPage(
  titlePanel("reactR HTMLWidget Example"),
  RBrowseOutput('widgetOutput')
)

server <- function(input, output, session) {
  output$widgetOutput <- renderRBrowse(
    RBrowse("Foopy doopy!")
  )
}

shinyApp(ui, server)
