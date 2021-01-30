library(shiny)
library(RBrowse)

ui <- fluidPage(
  titlePanel("RBrowse Example"),
  RBrowseOutput("widgetOutput")
)

server <- function(input, output, session) {
  assembly <- assembly("https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz", bgzip = TRUE)

  output$widgetOutput <- renderRBrowse(
    RBrowse("View",
      assembly = assembly
    )
  )
}

shinyApp(ui, server)
