library(shiny)
library(RBrowse)

ui <- fluidPage(
  titlePanel("JSON JBrowseR Example"),
  RBrowseOutput("widgetOutput")
)

server <- function(input, output, session) {
  config <- json_config("./config.json")

  output$widgetOutput <- renderRBrowse(
    RBrowse("JsonView",
            config = config,
            location = "10:29,838,737..29,838,819"
    )
  )
}

shinyApp(ui, server)
