library(shiny)
library(JBrowseR)

ui <- fluidPage(
  titlePanel("JBrowseR Example"),
  JBrowseROutput("widgetOutput")
)

server <- function(input, output, session) {
  # create the assembly configuration
  assembly <- assembly(
    "https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz",
    bgzip = TRUE,
    aliases = c("GRCh37"),
    refname_aliases = "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/hg19_aliases.txt"
  )

  df <- data.frame(
    chrom = c('1', '2'),
    start = c(123, 456),
    end = c(789, 101112),
    name = c('feature1', 'feature2')
  )

  df_track <- track_data_frame(df, "foo", assembly)

  # set up the final tracks object to be used
  tracks <- tracks(
    df_track
  )

  # determine what the browser displays by default
  default_session <- default_session(
    assembly,
    c(df_track),
    display_assembly = FALSE
  )


  output$widgetOutput <- renderJBrowseR(
    JBrowseR("View",
             assembly = assembly,
             tracks = tracks,
             location = "2:456",
             defaultSession = default_session
    )
  )
}

shinyApp(ui, server)
