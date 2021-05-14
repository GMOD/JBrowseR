library(shiny)
library(JBrowseR)

ui <- fluidPage(
  titlePanel("JSON JBrowseR Example"),
  JBrowseROutput("widgetOutput")
)

server <- function(input, output, session) {
  config <- json_config("./config.json")

  output$widgetOutput <- renderJBrowseR(
    JBrowseR("JsonView",
            config = config,
            location = "10:29,838,737..29,838,819"
    )
  )
}

shinyApp(ui, server)
