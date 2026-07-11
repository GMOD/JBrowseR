library(shiny)
library(JBrowseR)
library(bslib)

# Interactive analysis: a control that RE-RUNS the computation, not just a filter
# over a static file. A synthetic binned coverage signal over a stretch of hg38
# chr17 carries a peak near BRCA1. The slider sets the calling threshold (in SDs
# above the mean); every change reclassifies the bins in R, merges the called
# ones into intervals, and re-renders the track. The analysis lives in the
# server — swap `call_peaks` for MACS2 output, a DESeq2 contrast, or any R
# pipeline. Click a called peak to read it back.

bin <- 500
starts <- seq(43000000, 43124500, by = bin)
set.seed(1)
signal <- rnorm(length(starts), mean = 10, sd = 2)
peak_bins <- starts >= 43044000 & starts <= 43050000 # a bump near BRCA1
signal[peak_bins] <- signal[peak_bins] + seq(6, 14, length.out = sum(peak_bins))

# reclassify at a z-score threshold and merge adjacent called bins into intervals
call_peaks <- function(z_threshold) {
  z <- (signal - mean(signal)) / sd(signal)
  hit <- z > z_threshold
  runs <- rle(hit)
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

ui <- page_sidebar(
  theme = bs_theme(version = 5),
  title = "JBrowseR: interactive peak calling",
  sidebar = sidebar(
    sliderInput("threshold", "Calling threshold (z-score)",
      min = 1, max = 5, value = 2, step = 0.1
    ),
    textOutput("npeaks"),
    hr(),
    strong("Clicked peak"),
    verbatimTextOutput("selected")
  ),
  JBrowseROutput("browserOutput")
)

server <- function(input, output, session) {
  peaks <- reactive(call_peaks(input$threshold))

  output$npeaks <- renderText(paste(nrow(peaks()), "peaks called"))

  output$browserOutput <- renderJBrowseR(JBrowseR(
    "hg38",
    tracks = list(track_data_frame(peaks(), "called_peaks")),
    location = "17:43,000,000..43,125,000"
  ))

  output$selected <- renderPrint({
    req(input$selectedFeature)
    f <- input$selectedFeature
    cat(sprintf(
      "%s\n%s:%s..%s (%s bp)",
      f$name, f$refName, f$start, f$end, f$end - f$start
    ))
  })
}

shinyApp(ui, server)
