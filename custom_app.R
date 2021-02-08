library(shiny)
library(RBrowse)

ui <- fluidPage(
  titlePanel("RBrowse Example"),
  RBrowseOutput("widgetOutput")
)

server <- function(input, output, session) {
  assembly <- assembly("https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz", bgzip = TRUE)
  tracks <- tracks(
    track_alignments(
      "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/ultra-long-ont_hs37d5_phased.cram",
      assembly
    ),
    track_variant(
      "https://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh37/clinvar.vcf.gz",
      assembly
    ),
    track_wiggle(
      "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/reads_lr_skbr3.fa_ngmlr-0.2.3_mapped.bam.regions.bw",
      assembly
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
