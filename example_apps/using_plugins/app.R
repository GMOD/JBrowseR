library(shiny)
library(JBrowseR)
library(bslib)

ui <- fluidPage(
  # Overriding the default bootstrap theme is needed to get proper font size
  theme = bs_theme(version = 5),
  titlePanel("Using Plugins Example"),
  JBrowseROutput("browserOutput")
)


server <- function(input, output, session) {
  # using JBrowseR helper function to parse the config
  config <- json_config("./config.json")

  output$browserOutput <- renderJBrowseR(
    JBrowseR("JsonView",
            config = config,
            location = "1:20,000,000-20,500,000"
    )
  )
}

shinyApp(ui, server)
