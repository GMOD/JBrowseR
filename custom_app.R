library(shiny)
library(RBrowse)

ui <- fluidPage(
  titlePanel("RBrowse Example"),
  RBrowseOutput('widgetOutput')
)

# TODO: I'm going to try passing the custom configurations to View as strings, and then inside View calling JSON.parse
# to turn them into the correct JavaScript object.
#
# This should get around the issues I'm having with passing arrays from R to JS.
#
# Workflow:
#   1. call JSON.stringify() from ViewHg19 to get strings of the config
#   2. add the strings to this app.
#   3. call JSON.parse in View to turn the strings into the config objects
#   4. profit :)

server <- function(input, output, session) {
  assembly <- '{"name":"hg19","sequence":{"type":"ReferenceSequenceTrack","trackId":"GRCh37-ReferenceSequenceTrack","adapter":{"type":"BgzipFastaAdapter","fastaLocation":{"uri":"https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz"},"faiLocation":{"uri":"https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz.fai"},"gziLocation":{"uri":"https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz.gzi"}}},"aliases":["GRCh37"],"refNameAliases":{"adapter":{"type":"RefNameAliasAdapter","location":{"uri":"https://s3.amazonaws.com/jbrowse.org/genomes/hg19/hg19_aliases.txt"}}}}'

  tracks <- c(
    list(
      type = "FeatureTrack",
      trackId = "ncbi_gff_hg19",
      name = "NCBI RefSeq (GFF3Tabix)",
      assemblyNames = c("hg19"),
      category = c("Annotation"),
      adapter = list(
        type = "Gff3TabixAdapter",
        gffGzLocation = list(
          uri = "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/GRCh37_latest_genomic.sort.gff.gz"
        ),
        index = list(
          location = list(
            uri = "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/GRCh37_latest_genomic.sort.gff.gz.tbi"
          )
        )
      )
    )
  )

  defaultSession <- list(
    name = "My session",
    view = list(
      id = "linearGenomeView",
      type = "LinearGenomeView",
      tracks = c(
        list(
          type = "ReferenceSequenceTrack",
          configuration = "GRCh37-ReferenceSequenceTrack",
          displays = c(
            list(
              type = "LinearReferenceSequenceDisplay",
              configuration = "GRCh37-ReferenceSequenceTrack-LinearReferenceSequenceDisplay"
            )
          )
        ),
        list(
          type = "FeatureTrack",
          configuration = "ncbi_gff_hg19",
          displays = c(
            list(
              type = "LinearBasicDisplay",
              configuration = "ncbi_gff_hg19-LinearBasicDisplay"
            )
          )
        )
      )
    )
  )

  output$widgetOutput <- renderRBrowse(
    RBrowse("View",
            assembly = assembly,
            tracks = tracks,
            location = "10:29,838,737..29,838,819",
            defaultSession = defaultSession)
  )
}

shinyApp(ui, server)
