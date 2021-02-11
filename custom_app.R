library(shiny)
library(RBrowse)

ui <- fluidPage(
  titlePanel("JBrowseR Example"),
  RBrowseOutput("widgetOutput")
)

server <- function(input, output, session) {
  # create the assembly configuration
  assembly <- assembly("https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz", bgzip = TRUE)

  # create alignments, variant, and wiggle tracks
  alignments <- track_alignments(
    "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/ultra-long-ont_hs37d5_phased.cram",
    assembly
  )
  variant <- track_variant(
    "https://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh37/clinvar.vcf.gz",
    assembly
  )
  wiggle <- track_wiggle(
    "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/reads_lr_skbr3.fa_ngmlr-0.2.3_mapped.bam.regions.bw",
    assembly
  )

  # set up the final tracks object to be used
  tracks <- tracks(
    alignments,
    variant,
    wiggle
  )

  # determine what the browser displays by default
  default_session <- default_session(
    assembly,
    c(variant, wiggle),
    display_assembly = FALSE
  )

  # create a custom color palette theme for the browser
  theme <- theme("#311b92", "#0097a7", "#f57c00", "#d50000")

  output$widgetOutput <- renderRBrowse(
    RBrowse("View",
      assembly = assembly,
      tracks = tracks,
      location = "10:31,419,497..33,370,375",
      defaultSession = default_session,
      theme = theme
    )
  )
}

shinyApp(ui, server)
