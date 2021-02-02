library(shiny)
library(RBrowse)

ui <- fluidPage(
  titlePanel("RBrowse Example"),
  RBrowseOutput("widgetOutput")
)

server <- function(input, output, session) {
  assembly <- assembly("https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz", bgzip = TRUE)
  tracks <- tracks(
    track_alignments("https://s3.amazonaws.com/jbrowse.org/genomes/hg19/skbr3/reads_lr_skbr3.fa_ngmlr-0.2.3_mapped.down.bam",
      assembly_name = "hg19"
    )
  )

  output$widgetOutput <- renderRBrowse(
    RBrowse("View",
      assembly = assembly,
      tracks = tracks
    )
  )
}

shinyApp(ui, server)
