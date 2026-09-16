library(shiny)
library(JBrowseR)
library(bslib)

# Save and reopen a layout. The app reports whatever the user built --
# navigation, open tracks, added or rearranged views -- as
# `input$<outputId>_session`, in the shape the `session` option takes. Saving
# stores that value; restoring sends it back with update_jbrowse(), which
# restores it in the app on the page. Feeding the read-back into
# renderJBrowseRApp() instead would restore on every pan.

hg19 <- list(
  name = "hg19",
  uri = "https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz"
)

genes <- list(
  type = "FeatureTrack",
  trackId = "ncbi_refseq_hg19",
  name = "NCBI RefSeq genes",
  assemblyNames = list("hg19"),
  adapter = list(
    type = "Gff3TabixAdapter",
    uri = paste0(
      "https://jbrowse.org/genomes/hg19/ncbi_refseq/",
      "GRCh37_latest_genomic.sort.gff.gz"
    )
  )
)

opening_view <- list(
  type = "LinearGenomeView",
  assembly = "hg19",
  loc = "17:41,196,312..41,277,500"
)

ui <- page_sidebar(
  theme = bs_theme(version = 5),
  title = "JBrowseR: save and reopen a layout",
  sidebar = sidebar(
    p(
      "Navigate, open a track, split the view — then save. Restore brings",
      "that arrangement back."
    ),
    actionButton("save", "Save this layout", class = "btn-primary"),
    actionButton("restore", "Restore saved layout"),
    actionButton("reset", "Back to the opening view"),
    hr(),
    strong("Saved"),
    verbatimTextOutput("saved_summary")
  ),
  JBrowseRAppOutput("browser", height = "600px")
)

server <- function(input, output, session) {
  saved <- reactiveVal(NULL)

  output$browser <- renderJBrowseRApp(JBrowseRApp(
    assemblies = list(hg19),
    tracks = list(genes),
    views = list(opening_view)
  ))

  observeEvent(input$save, {
    saved(input$browser_session)
  })

  observeEvent(input$restore, {
    req(saved())
    update_jbrowse("browser", session = saved())
  })

  # `views` is not applied in place, so this rebuilds the app from its options
  observeEvent(input$reset, {
    update_jbrowse("browser", views = list(opening_view))
  })

  output$saved_summary <- renderPrint({
    s <- saved()
    if (is.null(s)) {
      cat("nothing saved yet")
    } else {
      views <- s$views
      cat(sprintf("%s view(s)\n", length(views)))
      for (v in views) {
        cat(sprintf(
          "  %s — %s track(s)\n",
          v$type, length(v$tracks)
        ))
      }
    }
  })
}

shinyApp(ui, server)
