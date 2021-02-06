#' Title
#'
#' @param track_data
#' @param assembly
#'
#' @return
#' @export
#'
#' @examples
track_variant <- function(track_data, assembly) {
  print("Variant track!")
  type <- "VariantTrack"
  name <- get_name(track_data)
  assembly_name <- get_assembly_name(assembly)
  track_id <- stringr::str_c(assembly_name, "_", name)
  index <- stringr::str_c(track_data, ".tbi")

  as.character(
    stringr::str_glue(
      "{{ ",
      '"type": "{type}", ',
      '"name": "{name}", ',
      '"assemblyNames": ["{assembly_name}"], ',
      '"trackId": "{track_id}", ',
      '"adapter": {{ ',
      '"type": "VcfTabixAdapter", ',
      '"vcfGzLocation": {{ "uri": "{track_data}" }}, ',
      '"index": {{ "location": {{ "uri": "{index}"  }} }}',
      "}}",
      "}}"
    )
  )
}
