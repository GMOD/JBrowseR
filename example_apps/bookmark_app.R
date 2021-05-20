library(shiny)
library(tibble)
library(DT)
library(JBrowseR)

ui <- fluidPage(
  titlePanel("JBrowseR Bookmark App"),
  JBrowseROutput("browserOutput"),
  tags$br(),
  actionButton("delete", label = "delete selected table rows", icon = icon('trash')),
  tags$br(),
  tags$br(),
  dataTableOutput("bookmarks")
)

server <- function(input, output, session) {
  output$browserOutput <- renderJBrowseR(
    JBrowseR("ViewHg38", location = "10:32,311,572..32,478,205")
  )

  # set up reactive df of bookmarks
  values <- reactiveValues()

  values$bookmark_df <- tibble::tibble(
    chrom = character(),
    start = numeric(),
    end = numeric(),
    name = character()
  )

  # add clicked region
  observeEvent(input$selectedFeature, {
    values$bookmark_df <- values$bookmark_df %>%
      add_row(
        chrom = input$selectedFeature$refName,
        start = input$selectedFeature$start,
        end = input$selectedFeature$end,
        name = input$selectedFeature$name
      )
  })

  # delete selected table rows
  observeEvent(input$delete, {
    if (!is.null(input$bookmarks_rows_selected)) {
      values$bookmark_df <- values$bookmark_df %>%
        filter(!row_number() %in% input$bookmarks_rows_selected)
    }
  })

  output$bookmarks <- DT::renderDT(values$bookmark_df)
}

shinyApp(ui, server)
