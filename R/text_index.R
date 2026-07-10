#' Describe a gene-name text-search index
#'
#' Builds an aggregate Trix text-search adapter so users can search the browser
#' by gene name. Pass the result as `text_search` to [JBrowseR()].
#'
#' Hub assemblies (e.g. `JBrowseR("hg38")`) already include gene search, so this
#' is only needed for custom assemblies with your own Trix index.
#'
#' @param ix URL to the `.ix` file.
#' @param ixx URL to the `.ixx` file.
#' @param meta URL to the `meta.json` file.
#' @param assembly Name of the assembly the index applies to.
#'
#' @return an aggregate text-search adapter list
#' @export
#'
#' @examples
#' text_index(
#'   "https://jbrowse.org/genomes/hg19/trix/hg19.ix",
#'   "https://jbrowse.org/genomes/hg19/trix/hg19.ixx",
#'   "https://jbrowse.org/genomes/hg19/trix/meta.json",
#'   "hg19"
#' )
text_index <- function(ix, ixx, meta, assembly) {
  list(
    type = "TrixTextSearchAdapter",
    textSearchAdapterId = paste0(assembly, "-index"),
    ixFilePath = list(uri = ix),
    ixxFilePath = list(uri = ixx),
    metaFilePath = list(uri = meta),
    assemblyNames = list(assembly)
  )
}
