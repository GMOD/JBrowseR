library(shiny)
library(JBrowseR)
library(bslib)

# A hub assembly (here hg38) ships gene-name search, so `location` can be a gene
# symbol like "BRCA1" with no extra setup.

ui <- fluidPage(
  theme = bs_theme(version = 5),
  titlePanel("JBrowseR: search by gene name"),
  JBrowseROutput("widgetOutput")
)

server <- function(input, output, session) {
  output$widgetOutput <- renderJBrowseR(JBrowseR(
    "hg38",
    tracks = tracks(track(
      "https://s3.amazonaws.com/jbrowse.org/genomes/GRCh38/ncbi_refseq/GCA_000001405.15_GRCh38_full_analysis_set.refseq_annotation.sorted.gff.gz",
      name = "NCBI RefSeq Genes"
    )),
    location = "BRCA1"
  ))
}

shinyApp(ui, server)
