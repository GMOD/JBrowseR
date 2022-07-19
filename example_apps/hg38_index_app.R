library(shiny)
library(JBrowseR)

ui <- fluidPage(titlePanel("JBrowseR Example"),
                JBrowseROutput("widgetOutput"))

server <- function(input, output, session) {
  hg38 <- assembly(
    "https://jbrowse.org/genomes/GRCh38/fasta/hg38.prefix.fa.gz",
    bgzip = TRUE,
    aliases = c("GRCh38"),
    refname_aliases = "https://s3.amazonaws.com/jbrowse.org/genomes/GRCh38/hg38_aliases.txt"
  )


  output$widgetOutput <- renderJBrowseR(JBrowseR(
    "View",
    location = "10:29,838,737..29,838,819",
    assembly = hg38,
    text_index = text_index(
      "https://jbrowse.org/genomes/GRCh38/trix/hg38.ix",
      "https://jbrowse.org/genomes/GRCh38/trix/hg38.ixx",
      "https://jbrowse.org/genomes/GRCh38/trix/meta.json",
      "hg38"
    )
  ))

}

shinyApp(ui, server)
