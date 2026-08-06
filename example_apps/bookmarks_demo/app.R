library(shiny)
library(JBrowseR)
library(bslib)
library(DT)

# An interactive tour of driving JBrowse 2 from Shiny: jump to genes of interest,
# add a track built from an R data frame, and bookmark features you click. The
# hg38 hub supplies the assembly and gene-name search, so navigation can use gene
# symbols directly.

ui <- fluidPage(
  theme = bs_theme(version = 5),
  titlePanel("JBrowseR interactive demo"),
  sidebarLayout(
    sidebarPanel(
      h4("Jump to a gene"),
      span("Navigate to genes of clinical interest:"),
      br(),
      actionButton("cyp", "CYP2C19 (pharmacogenomics)"),
      actionButton("tp53", "TP53 (tumor suppressor)"),
      actionButton("brca2", "BRCA2"),
      h4("Add an R data-frame track"),
      span("Render the regions in this table as a JBrowse track:"),
      tableOutput("regions"),
      actionButton("add", "Add track", icon = icon("plus")),
      h4("Bookmarks"),
      span("Click a feature in the browser to bookmark it, then select a row to
        navigate to it or delete it."),
      br(),
      actionButton("navigate", "Go to selected", icon = icon("arrow-right")),
      actionButton("delete", "Delete selected", icon = icon("trash")),
      DT::dataTableOutput("bookmarks")
    ),
    mainPanel(JBrowseROutput("browserOutput"))
  )
)

server <- function(input, output, session) {
  observeEvent(input$cyp, update_location("browserOutput", "CYP2C19"))
  observeEvent(input$tp53, update_location("browserOutput", "TP53"))
  observeEvent(input$brca2, update_location("browserOutput", "BRCA2"))

  genes <- list(
    uri =
    "https://jbrowse.org/genomes/GRCh38/ncbi_refseq/GCA_000001405.15_GRCh38_full_analysis_set.refseq_annotation.sorted.gff.gz",
    name = "NCBI RefSeq Genes"
  )
  variants <- list(
    uri =
    "https://jbrowse.org/genomes/GRCh38/variants/ALL.wgs.shapeit2_integrated_snvindels_v2a.GRCh38.27022019.sites.vcf.gz",
    name = "1000 Genomes Variants"
  )

  regions_df <- data.frame(
    chrom = c("10", "17", "13"),
    start = c(94762681, 7668402, 32315086),
    end = c(94855547, 7687550, 32400266),
    name = c("CYP2C19", "TP53", "BRCA2")
  )
  output$regions <- renderTable(regions_df)

  extra <- reactiveVal(list())
  observeEvent(input$add, {
    extra(list(track_data_frame(regions_df, "genes_of_interest")))
  })

  # Adding the track is the one thing here that does rebuild the browser, since
  # the track list is part of what it is built from. Reading the reported
  # location under isolate() is what makes that survivable: the rebuild lands
  # where the user was rather than back at the start, and isolating it keeps
  # this from re-running every time they pan.
  output$browserOutput <- renderJBrowseR(JBrowseR(
    "hg38",
    tracks = c(list(genes, variants), extra()),
    location = isolate(input$browserOutput_location) %||% "CYP2C19"
  ))

  bookmarks <- reactiveVal(data.frame(
    chrom = character(), start = numeric(), end = numeric(), name = character()
  ))
  observeEvent(input$browserOutput_selected_feature, {
    f <- input$browserOutput_selected_feature
    bookmarks(rbind(bookmarks(), data.frame(
      chrom = f$refName, start = f$start, end = f$end, name = f$name %||% ""
    )))
  })
  output$bookmarks <- DT::renderDT(bookmarks(), selection = "single")

  observeEvent(input$navigate, {
    row <- input$bookmarks_rows_selected
    if (length(row)) {
      b <- bookmarks()[row, ]
      update_location("browserOutput", paste0(b$chrom, ":", b$start, "..", b$end))
    }
  })
  observeEvent(input$delete, {
    row <- input$bookmarks_rows_selected
    if (length(row)) {
      bookmarks(bookmarks()[-row, ])
    }
  })
}

`%||%` <- function(a, b) if (is.null(a)) b else a

shinyApp(ui, server)
