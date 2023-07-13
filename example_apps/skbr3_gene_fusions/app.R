library(shiny)
library(tibble)
library(JBrowseR)
library(bslib)

ui <- fluidPage(
  # Overriding the default bootstrap theme is needed to get proper font size
  theme = bs_theme(version = 5),
  titlePanel("SKBR3 Gene Fusions"),
  dataTableOutput("gene_fusions"),
  JBrowseROutput("browserOutput")
)

server <- function(input, output, session) {
  hg19 <- assembly(
    "https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz",
    bgzip = TRUE,
    aliases = c("GRCh37"),
    refname_aliases = "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/hg19_aliases.txt"
  )

  pacbio <- track_alignments(
    "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/skbr3/reads_lr_skbr3.fa_ngmlr-0.2.3_mapped.down.bam",
    hg19
  )

  gene_fusions <- as.data.frame(tribble(
    ~chrom, ~start, ~end, ~name,
    "chr14", 50234326, 50249909, "KLHDC2",
    "chr8", 121547985, 121825513, "SNTB1",
    "chr17", 76670130, 76778379, "CYTH1",
    "chr8", 117654369, 117779164, "EIF3H",
    "chr20", 34213953, 34252878, "CPNE1",
    "chr20", 47240790, 47444420, "PREX1",
    "chr17", 38060848, 38076107, "GSDMB",
    "chr8", 125500726, 125551699, "TATDN1",
    "chr8", 116962736, 117337297, "LINC00536",
    "chr8", 128806779, 129113499, "PVT1"
  ))

  fusion_track <- track_data_frame(gene_fusions, "Gene fusions", hg19)

  track_list <- tracks(pacbio, fusion_track)

  default_session <- default_session(
    hg19,
    c(pacbio, fusion_track)
  )

  output$browserOutput <- renderJBrowseR(
    JBrowseR("View",
             assembly = hg19,
             tracks = track_list,
             location = "chr14:50,234,326-50,249,909",
             defaultSession = default_session
    )
  )
}

shinyApp(ui, server)
