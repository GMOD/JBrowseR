library(shiny)
library(JBrowseR)
library(bslib)

# the hosted hg19 hub has no refName aliases, so name the assembly with its
# alias file: the data below uses bare chromosome names
hg19 <- assembly(
  "https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz",
  refname_aliases = "https://jbrowse.org/genomes/hg19/hg19_aliases.txt"
)

# View features you build in R (here a small data frame) directly on the genome,
# with no files and no web server. Click a feature to read it back in Shiny.

ui <- fluidPage(
  theme = bs_theme(version = 5),
  titlePanel("JBrowseR: a track from an R data frame"),
  JBrowseROutput("widgetOutput"),
  verbatimTextOutput("selected")
)

server <- function(input, output, session) {
  df <- data.frame(
    chrom = c("1", "2"),
    start = c(123, 456),
    end = c(789, 101112),
    name = c("feature1", "feature2")
  )

  output$widgetOutput <- renderJBrowseR(JBrowseR(
    hg19,
    tracks = list(track_data_frame(df, "my_features")),
    location = "2:1..101200"
  ))

  output$selected <- renderPrint({
    req(input$selectedFeature)
    input$selectedFeature$name
  })
}

shinyApp(ui, server)
