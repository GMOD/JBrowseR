library(shiny)
library(JBrowseR)
library(bslib)



ui <- fluidPage(
  # Overriding the default bootstrap theme is needed to get proper font size
  theme = bs_theme(version = 5),
  titlePanel("JBrowseR Example"),
  JBrowseROutput("widgetOutput")
)

server <- function(input, output, session) {
  output$widgetOutput <- renderJBrowseR(JBrowseR("ViewHg19",
    location = "10:29,838,737..29,838,819"
  ))
}

shinyApp(ui, server)
