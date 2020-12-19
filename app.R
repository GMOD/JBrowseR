library(shiny)
library(RBrowse)

ui <- fluidPage(
  titlePanel("RBrowse Example"),
  RBrowseOutput('widgetOutput')
)

server <- function(input, output, session) {
  output$widgetOutput <- renderRBrowse(
    RBrowse("10:29,838,737..29,838,819")
  )
}

shinyApp(ui, server)
