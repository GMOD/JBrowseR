#' Describe a data track by its URL
#'
#' Builds a loose track spec — `list(uri = url)` plus whatever you pass — that
#' the view expands into a full track config when it loads, inferring the track
#' type and adapter from the file extension with JBrowse's own format plugins
#' (the same inference the "Add track" flow uses). No extension table lives in
#' R, so every format a bundled plugin recognizes works: `.bam`/`.cram`
#' (alignments), `.vcf` (variants), `.gff`/`.gff3`/`.gtf`/`.bed` (features),
#' `.bb`/`.bigBed` (features), `.bw`/`.bigWig` (quantitative), `.hic` (Hi-C), and
#' more. A bgzipped file (`.gff.gz`, …) resolves to its indexed tabix adapter, a
#' plain one to the whole-file adapter. JBrowse derives index locations
#' (`.bai`/`.crai`/`.tbi`) and, for CRAM, the reference from the assembly, so
#' only the data URL is required.
#'
#' @param url URL to the track data.
#' @param name Track display name. Left `NULL`, the view derives it from the
#'   file's base name.
#' @param track_id A unique id for the track. Left `NULL`, the view derives one.
#' @param assembly_names Assembly name(s) the track belongs to. Usually left
#'   `NULL` — [JBrowseR()] backfills it from the loaded assembly.
#' @param index URL of the index file when it isn't the conventional sibling of
#'   `url` (`.bai`/`.crai`/`.tbi`). A `.csi` index is detected by extension.
#' @param ... Extra config merged onto the track, overriding the inferred
#'   defaults (e.g. `category = list("Genes")`, or a `type = "AlignmentsTrack"`
#'   override).
#'
#' @return a loose track spec list
#' @export
#'
#' @examples
#' track("https://jbrowse.org/genomes/hg19/gencode.v19.sorted.gff.gz", name = "Genes")
track <- function(url, name = NULL, track_id = NULL, assembly_names = NULL,
                  index = NULL, ...) {
  spec <- drop_null(list(
    uri = url,
    name = name,
    trackId = track_id,
    index = index,
    assemblyNames = as_json_array(assembly_names)
  ))
  utils::modifyList(spec, list(...))
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
