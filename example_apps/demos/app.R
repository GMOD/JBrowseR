library(shiny)
library(JBrowseR)
library(bslib)

# Every example_apps/ demo in one app, one tab each. The single-purpose apps are
# the ones to read and copy — each is a page of code with nothing else in it —
# while this is what gets hosted, so a plan's app limit buys all of the demos
# rather than a subset of them.

refseq_hg38 <- paste0(
  "https://jbrowse.org/genomes/GRCh38/ncbi_refseq/",
  "GCA_000001405.15_GRCh38_full_analysis_set.refseq_annotation.sorted.gff.gz"
)

# --- interactive peak calling ------------------------------------------------
# A synthetic binned coverage signal over hg38 chr17 with a bump near BRCA1. The
# slider re-runs the calling, it does not filter a precomputed file.
bin <- 500
starts <- seq(43000000, 43124500, by = bin)
set.seed(1)
signal <- rnorm(length(starts), mean = 10, sd = 2)
peak_bins <- starts >= 43044000 & starts <= 43050000
signal[peak_bins] <- signal[peak_bins] + seq(6, 14, length.out = sum(peak_bins))

call_peaks <- function(z_threshold) {
  z <- (signal - mean(signal)) / sd(signal)
  runs <- rle(z > z_threshold)
  ends <- cumsum(runs$lengths)
  begins <- ends - runs$lengths + 1
  called <- runs$values
  data.frame(
    chrom = "17",
    start = starts[begins[called]],
    end = starts[ends[called]] + bin,
    name = if (any(called)) paste0("peak", seq_len(sum(called))) else character()
  )
}

ui <- page_navbar(
  id = "tab",
  theme = bs_theme(version = 5),
  title = "JBrowseR demos",
  header = tags$p(
    class = "text-muted px-3 pt-2 mb-0",
    "Each tab is a single-purpose app in ",
    tags$a(
      href = "https://github.com/GMOD/JBrowseR/tree/main/example_apps",
      "example_apps/"
    ), "."
  ),
  nav_panel(
    "Gene search",
    p(
      "A hub assembly ships a gene-name search index, so ", code("location"),
      " takes a symbol like ", code("BRCA1"), " with no extra setup."
    ),
    JBrowseROutput("search")
  ),
  nav_panel(
    "Your data",
    p(
      "A data frame becomes a track with no file and no server. Click a feature",
      " to read it back in Shiny."
    ),
    JBrowseROutput("dataframe"),
    verbatimTextOutput("dataframe_selected")
  ),
  nav_panel(
    "Live analysis",
    layout_sidebar(
      sidebar = sidebar(
        sliderInput("threshold", "Calling threshold (z-score)",
          min = 1, max = 5, value = 2, step = 0.1
        ),
        textOutput("npeaks"),
        hr(),
        strong("Clicked peak"),
        verbatimTextOutput("peak_selected")
      ),
      p(
        "The slider re-runs the peak calling in R and repaints the track — swap",
        " ", code("call_peaks()"), " for MACS2 output or a DESeq2 contrast."
      ),
      JBrowseROutput("peaks")
    )
  ),
  nav_panel(
    "Cancer SVs",
    p(
      "SKBR3 PacBio long reads on hg19 with the structural variants Sniffles",
      " called from them. Long reads span breakpoints short reads cannot."
    ),
    actionButton("klhdc2", "KLHDC2 fusion"),
    actionButton("tatdn1", "TATDN1/GSDMB region"),
    actionButton("erbb2", "ERBB2 (HER2)"),
    JBrowseROutput("sv")
  ),
  nav_panel(
    "config.json",
    p(
      "The escape hatch: a whole JBrowse 2 config, the same file the web app",
      " and desktop read."
    ),
    JBrowseROutput("config")
  ),
  nav_panel(
    "Plugins",
    p(
      "Plugins are declared in a config, so ", code("config ="),
      " is how a JBrowse 2 plugin gets loaded — here ModifyHTTPHeaders."
    ),
    JBrowseROutput("plugins")
  )
)

server <- function(input, output, session) {
  # The open tab lives in ?tab=, so a link to a demo opens on that demo.
  isolate({
    requested <- parseQueryString(session$clientData$url_search)$tab
    if (!is.null(requested)) nav_select("tab", requested)
  })
  observeEvent(input$tab, {
    updateQueryString(
      paste0("?tab=", URLencode(input$tab, reserved = TRUE)),
      mode = "replace"
    )
  })

  output$search <- renderJBrowseR(JBrowseR(
    "hg38",
    tracks = tracks(track(refseq_hg38, name = "NCBI RefSeq Genes")),
    location = "BRCA1"
  ))

  features <- data.frame(
    chrom = c("1", "2"),
    start = c(123, 456),
    end = c(789, 101112),
    name = c("feature1", "feature2")
  )
  output$dataframe <- renderJBrowseR(JBrowseR(
    "hg19",
    tracks = list(track_data_frame(features, "my_features")),
    location = "2:1..101200"
  ))
  output$dataframe_selected <- renderPrint({
    req(input$selectedFeature)
    input$selectedFeature$name
  })

  peaks <- reactive(call_peaks(input$threshold))
  output$npeaks <- renderText(paste(nrow(peaks()), "peaks called"))
  output$peaks <- renderJBrowseR(JBrowseR(
    "hg38",
    tracks = list(track_data_frame(peaks(), "called_peaks")),
    location = "17:43,000,000..43,125,000"
  ))
  output$peak_selected <- renderPrint({
    req(input$selectedFeature)
    f <- input$selectedFeature
    cat(sprintf(
      "%s\n%s:%s..%s (%s bp)",
      f$name, f$refName, f$start, f$end, f$end - f$start
    ))
  })

  loc <- reactiveVal("17:37,686,000..37,730,000")
  observeEvent(input$klhdc2, loc("14:50,230,000..50,255,000"))
  observeEvent(input$tatdn1, loc("8:125,490,000..125,560,000"))
  observeEvent(input$erbb2, loc("17:37,686,000..37,730,000"))
  output$sv <- renderJBrowseR(JBrowseR(
    "hg19",
    tracks = tracks(
      track(
        paste0(
          "https://jbrowse.org/genomes/hg19/SKBR3/",
          "reads_lr_skbr3.fa_ngmlr-0.2.3_mapped.bam.sniffles1kb_auto_l8_s5_noalt.filtered.vcf.gz"
        ),
        name = "Sniffles SV calls"
      ),
      track(
        paste0(
          "https://jbrowse.org/genomes/hg19/skbr3/",
          "reads_lr_skbr3.fa_ngmlr-0.2.3_mapped.down.bam"
        ),
        name = "SKBR3 PacBio long reads"
      )
    ),
    location = loc()
  ))

  output$config <- renderJBrowseR(JBrowseR(
    config = "./config.json",
    location = "10:29,838,737..29,838,819"
  ))

  output$plugins <- renderJBrowseR(JBrowseR(
    config = "./plugins_config.json",
    location = "1:20,000,000-20,500,000"
  ))
}

shinyApp(ui, server)
