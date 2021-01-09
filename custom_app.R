library(shiny)
library(RBrowse)

ui <- fluidPage(
  titlePanel("RBrowse Example"),
  RBrowseOutput('widgetOutput')
)

server <- function(input, output, session) {
  assembly <- list(
    name =  "hg19",
    sequence = list(
      type = "ReferenceSequenceTrack",
      trackId = "GRCh37-ReferenceSequenceTrack",
      adapter = list(
        type = "BgzipFastaAdapter",
        fastaLocation = list(
          uri = "https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz"
        ),
        faiLocation = list(
          uri = "https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz.fai"
        ),
        gziLocation = list(
          uri = "https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz.gzi"
        )
      )
    ),
    aliases = c("GRCh37"),
    refNameAliases = list(
      adapter = list(
        type = "RefNameAliasAdapter",
        location = list(
          uri = "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/hg19_aliases.txt"
        )
      )
    )
  )

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
