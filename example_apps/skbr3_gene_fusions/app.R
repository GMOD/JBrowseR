library(shiny)
library(JBrowseR)
library(bslib)

# SKBR3 is a widely studied HER2+ breast cancer cell line with a heavily
# rearranged genome. Here we view PacBio long reads aligned to hg19 alongside
# the structural variants called from them by Sniffles. Long reads span
# breakpoints that short reads cannot, revealing the cell line's fusions and
# large deletions. Buttons jump to a few of its known rearrangements.

ui <- fluidPage(
  theme = bs_theme(version = 5),
  titlePanel("SKBR3 breast cancer: long-read structural variants"),
  actionButton("klhdc2", "KLHDC2 fusion"),
  actionButton("tatdn1", "TATDN1/GSDMB region"),
  actionButton("erbb2", "ERBB2 (HER2)"),
  JBrowseROutput("browserOutput")
)

server <- function(input, output, session) {
  loc <- reactiveVal("chr17:37,686,000..37,730,000")

  observeEvent(input$klhdc2, loc("chr14:50,230,000..50,255,000"))
  observeEvent(input$tatdn1, loc("chr8:125,490,000..125,560,000"))
  observeEvent(input$erbb2, loc("chr17:37,686,000..37,730,000"))

  output$browserOutput <- renderJBrowseR(JBrowseR(
    "hg19",
    tracks = tracks(
      track(
        "https://jbrowse.org/genomes/hg19/SKBR3/reads_lr_skbr3.fa_ngmlr-0.2.3_mapped.bam.sniffles1kb_auto_l8_s5_noalt.filtered.vcf.gz",
        name = "Sniffles SV calls"
      ),
      track(
        "https://jbrowse.org/genomes/hg19/skbr3/reads_lr_skbr3.fa_ngmlr-0.2.3_mapped.down.bam",
        name = "SKBR3 PacBio long reads"
      )
    ),
    location = loc()
  ))
}

shinyApp(ui, server)
