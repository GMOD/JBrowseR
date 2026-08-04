library(shiny)
library(JBrowseR)
library(bslib)

# Save and reopen a layout. The app reports whatever the user built --
# navigation, open tracks, added or rearranged views -- as
# `input$<outputId>_session`, in the same shape `session =` takes. So "save"
# is storing that value and "restore" is handing it back.
#
# Note the two are deliberately not the same reactive. `current` only ever
# tracks the browser; `restored` only ever feeds it. Wiring the read-back
# straight into renderJBrowseRApp() would rebuild the app every time the user
# panned, throwing away the state it was meant to preserve.

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
  init = list(assembly = "hg19", loc = "17:41,196,312..41,277,500")
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
  # What renderJBrowseRApp reads: NULL opens `views`, a snapshot restores it.
  # Carries a nonce because reactiveVal compares with identical() and will not
  # invalidate on an unchanged value — without it, panning away and hitting
  # Restore a second time would silently do nothing.
  restored <- reactiveVal(NULL)

  output$browser <- renderJBrowseRApp(JBrowseRApp(
    assemblies = list(hg19),
    tracks = list(genes),
    views = list(opening_view),
    session = restored()$snapshot
  ))

  observeEvent(input$save, {
    saved(input$browser_session)
  })

  observeEvent(input$restore, {
    req(saved())
    restored(list(snapshot = saved(), nonce = input$restore))
  })

  observeEvent(input$reset, {
    restored(NULL)
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
