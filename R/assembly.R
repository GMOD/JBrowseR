#' Describe a genome assembly from a FASTA URL
#'
#' Builds an assembly config for a custom genome. JBrowse derives the index
#' locations (`.fai`, and `.gzi` for bgzip) from the FASTA URL automatically, so
#' only the FASTA is required.
#'
#' For common human/model genomes you do not need this at all — pass a hub name
#' straight to [JBrowseR()] (e.g. `JBrowseR("hg38")`) and the assembly, reference
#' name aliases, cytobands, and gene-name search all come preconfigured.
#'
#' @param fasta URL to the FASTA. A `.gz` file is treated as bgzip-compressed
#'   (`BgzipFastaAdapter`), otherwise as plain indexed FASTA
#'   (`IndexedFastaAdapter`).
#' @param name Assembly name. Defaults to the FASTA file's base name.
#' @param aliases Reference-name aliases for the assembly (e.g. `"GRCh37"`).
#' @param refname_aliases URL to a reference-name alias table mapping e.g. `1`
#'   to `chr1`.
#' @param bgzip Force bgzip vs indexed FASTA. Defaults to autodetection from the
#'   `.gz` extension.
#'
#' @return an assembly config list for [JBrowseR()]
#' @export
#'
#' @examples
#' assembly(
#'   "https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz",
#'   aliases = "GRCh37"
#' )
assembly <- function(fasta, name = NULL, aliases = NULL, refname_aliases = NULL,
                     bgzip = NULL) {
  name <- name %||% base_name(fasta)
  bgzip <- bgzip %||% endsWith(fasta, ".gz")

  out <- list(
    name = name,
    sequence = list(
      type = "ReferenceSequenceTrack",
      trackId = paste0(name, "-ReferenceSequenceTrack"),
      adapter = list(
        type = if (bgzip) "BgzipFastaAdapter" else "IndexedFastaAdapter",
        uri = fasta
      )
    )
  )
  if (!is.null(aliases)) {
    out$aliases <- as.list(aliases)
  }
  if (!is.null(refname_aliases)) {
    out$refNameAliases <- list(
      adapter = list(type = "RefNameAliasAdapter", uri = refname_aliases)
    )
  }
  out
}
