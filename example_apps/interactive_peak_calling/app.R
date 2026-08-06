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

# The location read-back is the string the location box shows, so it is grouped
# for reading ("chr17:43,044,295..43,125,483") and has to have its commas
# stripped before it is arithmetic. Returns NULL for anything that isn't one
# plain region, and hands back 0-based half-open coordinates to match what
# track_data_frame() takes.
#
# The refName it gives is the assembly's own — hg38 says "chr17" — which need
# not be what your data frame calls it. JBrowse aliases the two for display, so
# the track renders and only a string comparison in R notices. `bare_ref` is
# how this app reconciles its "17" with the browser's "chr17".
parse_locstring <- function(loc) {
  # a view split across several regions gives them space-separated
  if (grepl(" ", loc, fixed = TRUE)) {
    return(NULL)
  }
  # a view spanning several assemblies prefixes the refName with {assemblyName}
  loc <- sub("^\\{[^}]*\\}", "", loc)
  m <- regmatches(loc, regexec("^(.+):([0-9,]+)\\.\\.([0-9,]+)$", loc))[[1]]
  if (length(m) != 4) {
    return(NULL)
  }
  num <- function(x) as.numeric(gsub(",", "", x))
  # the printed start is 1-based inclusive
  list(ref_name = m[2], start = num(m[3]) - 1, end = num(m[4]))
}

bare_ref <- function(x) sub("^chr", "", x)

ui <- page_sidebar(
  theme = bs_theme(version = 5),
  title = "JBrowseR: interactive peak calling",
  sidebar = sidebar(
    sliderInput("threshold", "Calling threshold (z-score)",
      min = 1, max = 5, value = 2, step = 0.1
    ),
    textOutput("npeaks"),
    hr(),
    strong("In view"),
    verbatimTextOutput("in_view"),
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

  # Panning or zooming the browser sets `<outputId>_location`. Reading it drives
  # a *different* output here on purpose: feeding it back into the reactive
  # behind renderJBrowseR() would rebuild the widget on every pan, and a rebuild
  # resets the very view that produced the value.
  output$in_view <- renderPrint({
    req(input$browserOutput_location)
    region <- parse_locstring(input$browserOutput_location)
    if (is.null(region)) {
      cat(input$browserOutput_location) # split view: several regions at once
    } else {
      p <- peaks()
      inside <- bare_ref(p$chrom) == bare_ref(region$ref_name) &
        p$end > region$start & p$start < region$end
      cat(sprintf(
        "%s\n%s of %s peaks visible",
        input$browserOutput_location, sum(inside), nrow(p)
      ))
    }
  })

  output$selected <- renderPrint({
    req(input$browserOutput_selected_feature)
    f <- input$browserOutput_selected_feature
    cat(sprintf(
      "%s\n%s:%s..%s (%s bp)",
      f$name, f$refName, f$start, f$end, f$end - f$start
    ))
  })
}

shinyApp(ui, server)
