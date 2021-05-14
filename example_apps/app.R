library(shiny)
library(JBrowseR)

ui <- fluidPage(
  titlePanel("JBrowseR Example"),
  JBrowseROutput("widgetOutput")
)

server <- function(input, output, session) {
  output$widgetOutput <- renderJBrowseR(JBrowseR("ViewHg19",
    location = "10:29,838,737..29,838,819"
  ))
}

shinyApp(ui, server)
