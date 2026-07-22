#' Describe a genome assembly from a FASTA URL
#'
#' Builds an assembly config for a custom genome using the flat `{ name, uri }`
#' shorthand: JBrowse itself picks the concrete adapter type
#' (`IndexedFastaAdapter`/`BgzipFastaAdapter`/`TwoBitAdapter`) from the extension,
#' derives the `.fai`/`.gzi` index locations, and fills in the reference sequence
#' track when the config loads, so only the FASTA URL is required and no
#' adapter-type table lives in R.
#'
#' For common human/model genomes you do not need this at all — pass a hub name
#' straight to [JBrowseR()] (e.g. `JBrowseR("hg38")`) and the assembly, reference
#' name aliases, cytobands, and gene-name search all come preconfigured.
#'
#' @param fasta URL to the sequence: a `.fa`/`.fasta` (optionally bgzipped) or a
#'   `.2bit`. The adapter type is inferred from the extension by JBrowse.
#' @param name Assembly name. Defaults to the FASTA file's base name.
#' @param aliases Reference-name aliases for the assembly (e.g. `"GRCh37"`).
#' @param refname_aliases URL to a reference-name alias table mapping e.g. `1`
#'   to `chr1`.
#'
#' @return an assembly config list for [JBrowseR()]
#' @export
#'
#' @examples
#' assembly(
#'   "https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz",
#'   aliases = "GRCh37"
#' )
assembly <- function(fasta, name = NULL, aliases = NULL, refname_aliases = NULL) {
  # flat shorthand: core expands { name, uri } into the full sequence track, and
  # the same bare { uri } into a RefNameAliasAdapter
  drop_null(list(
    name = name %||% base_name(fasta),
    uri = fasta,
    aliases = as_json_array(aliases),
    refNameAliases = if (is.null(refname_aliases)) NULL else list(uri = refname_aliases)
  ))
}
