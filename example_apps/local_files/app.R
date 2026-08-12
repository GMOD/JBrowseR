library(shiny)
library(JBrowseR)
library(bslib)

# View a file from the user's own machine, with nothing hosting it. `local_files`
# ships the bytes into the browser, where JBrowse reads them by byte range — so
# an indexed file stays indexed and there is no server, no CORS, and no public
# bucket in the way.
#
# The names matter and are the whole API: each entry is registered under its
# name, and a track's `uri` refers to it as if it were a URL, so the extension
# still picks the adapter. Shiny's fileInput stages uploads under generated
# paths (`0.bam`, `1.bam`), which is why this passes a *named* vector built from
# the `name` column — the auto-pickup of a sibling index cannot help here,
# because the staged files are not siblings of anything. Select the index
# alongside the data file and it arrives under its own name.

ui <- fluidPage(
  theme = bs_theme(version = 5),
  titlePanel("JBrowseR: a file from your machine, unhosted"),
  fileInput(
    "files",
    "Choose a data file and its index (e.g. reads.bam and reads.bam.bai)",
    multiple = TRUE
  ),
  helpText(
    "Nothing is uploaded to a web server for JBrowse to read: the bytes go",
    "into the page and the browser seeks within them."
  ),
  JBrowseROutput("browser")
)

server <- function(input, output, session) {
  # the file whose extension names a track — the one that is not an index
  data_file <- reactive({
    req(input$files)
    names <- input$files$name
    names[!grepl("\\.(tbi|csi|bai|crai|fai|gzi)$", names)][1]
  })

  output$browser <- renderJBrowseR({
    req(data_file())
    JBrowseR(
      "hg38",
      tracks = list(list(uri = data_file(), name = data_file())),
      # `name` is what the track refers to; `datapath` is where Shiny staged it
      local_files = stats::setNames(input$files$datapath, input$files$name)
    )
  })
}

shinyApp(ui, server)
