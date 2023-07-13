library(shiny)
library(JBrowseR)
library(bslib)

ui <- fluidPage(
  # Overriding the default bootstrap theme is needed to get proper font size
  theme = bs_theme(version = 5),
  tags$head(
    tags$style(HTML(
      "html { font-size: 14px }"
    ))
  ),
  titlePanel("JBrowseR Example"),
  JBrowseROutput("widgetOutput")
)

server <- function(input, output, session) {
  # create the assembly configuration
  assembly <- assembly(
    "https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz",
    bgzip = TRUE,
    aliases = c("GRCh37"),
    refname_aliases = "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/hg19_aliases.txt"
  )

  # create alignments, variant, feature, and wiggle tracks
  alignments <- track_alignments(
    "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/ultra-long-ont_hs37d5_phased.cram",
    assembly
  )
  variant <- track_variant(
    "https://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh37/clinvar.vcf.gz",
    assembly
  )
  feature <- track_feature(
    "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/ncbi_refseq/GRCh37_latest_genomic.sort.gff.gz",
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
    feature,
    wiggle
  )

  # determine what the browser displays by default
  default_session <- default_session(
    assembly,
    c(variant, wiggle, feature),
    display_assembly = FALSE
  )

  # create a custom color palette theme for the browser
  theme <- theme("#311b92", "#0097a7", "#f57c00", "#d50000")

  output$widgetOutput <- renderJBrowseR(
    JBrowseR("View",
      assembly = assembly,
      tracks = tracks,
      location = "10:31,419,497..33,370,375",
      defaultSession = default_session,
      theme = theme
    )
  )
}

shinyApp(ui, server)
