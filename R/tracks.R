#' Describe a data track from its URL
#'
#' Builds a track config, inferring the track type and adapter from the file
#' extension. JBrowse derives index locations (`.bai`/`.crai`/`.tbi`) and, for
#' CRAM, the reference sequence adapter from the assembly, so only the data URL
#' is required.
#'
#' Recognized extensions: `.bam`/`.cram` (alignments), `.vcf.gz` (variants),
#' `.gff`/`.gff3`/`.bed` gzipped (features), `.bb`/`.bigBed` (features),
#' `.bw`/`.bigWig` (quantitative).
#'
#' @param url URL to the track data.
#' @param name Track display name. Defaults to the file's base name.
#' @param type Override the inferred track type (e.g. `"AlignmentsTrack"`).
#' @param adapter_type Override the inferred adapter type.
#' @param track_id A unique id for the track. Defaults to `name`.
#' @param assembly_names Assembly name(s) the track belongs to. Usually left
#'   `NULL` — [JBrowseR()] backfills it from the loaded assembly.
#' @param ... Extra config merged into the track (e.g. `category = list("Genes")`).
#'
#' @return a track config list
#' @export
#'
#' @examples
#' track("https://jbrowse.org/genomes/hg19/gencode.v19.sorted.gff.gz", name = "Genes")
track <- function(url, name = NULL, type = NULL, adapter_type = NULL,
                  track_id = NULL, assembly_names = NULL, ...) {
  detected <- detect_track(url)
  name <- name %||% base_name(url)

  out <- list(
    type = type %||% detected$track,
    trackId = track_id %||% name,
    name = name,
    adapter = list(type = adapter_type %||% detected$adapter, uri = url)
  )
  if (!is.null(assembly_names)) {
    out$assemblyNames <- as.list(assembly_names)
  }
  extra <- list(...)
  if (length(extra) > 0) {
    out <- utils::modifyList(out, extra)
  }
  out
}

#' Collect tracks into a list for JBrowseR
#'
#' A thin readability wrapper around `list()` that gathers [track()] configs
#' into the list [JBrowseR()] expects.
#'
#' @param ... track configs, e.g. from [track()]
#'
#' @return a list of track configs
#' @export
#'
#' @examples
#' tracks(
#'   track("https://example.com/genes.gff.gz", name = "Genes"),
#'   track("https://example.com/reads.bam", name = "Reads")
#' )
tracks <- function(...) {
  list(...)
}

# extension -> (track type, adapter type)
detect_track <- function(url) {
  ext <- url |> sub("[?#].*$", "", x = _) |> sub("[.]gz$", "", x = _)
  ext <- tolower(sub(".*[.]", "", ext))
  switch(ext,
    bam = list(track = "AlignmentsTrack", adapter = "BamAdapter"),
    cram = list(track = "AlignmentsTrack", adapter = "CramAdapter"),
    vcf = list(track = "VariantTrack", adapter = "VcfTabixAdapter"),
    gff = list(track = "FeatureTrack", adapter = "Gff3TabixAdapter"),
    gff3 = list(track = "FeatureTrack", adapter = "Gff3TabixAdapter"),
    gtf = list(track = "FeatureTrack", adapter = "GtfAdapter"),
    bed = list(track = "FeatureTrack", adapter = "BedTabixAdapter"),
    bb = list(track = "FeatureTrack", adapter = "BigBedAdapter"),
    bigbed = list(track = "FeatureTrack", adapter = "BigBedAdapter"),
    bw = list(track = "QuantitativeTrack", adapter = "BigWigAdapter"),
    bigwig = list(track = "QuantitativeTrack", adapter = "BigWigAdapter"),
    stop(
      sprintf(
        "could not infer a track type from '%s'; pass type= and adapter_type=",
        url
      ),
      call. = FALSE
    )
  )
}
