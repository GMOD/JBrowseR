#' Describe a data track from its URL
#'
#' Builds a track config, inferring the track type and adapter from the file
#' extension. JBrowse derives index locations (`.bai`/`.crai`/`.tbi`) and, for
#' CRAM, the reference sequence adapter from the assembly, so only the data URL
#' is required.
#'
#' Recognized extensions: `.bam`/`.cram` (alignments), `.vcf.gz` (variants),
#' `.gff`/`.gff3`/`.gtf`/`.bed` gzipped (features), `.bb`/`.bigBed` (features),
#' `.bw`/`.bigWig` (quantitative), `.hic` (Hi-C contact matrix).
#'
#' @param url URL to the track data.
#' @param name Track display name. Defaults to the file's base name.
#' @param type Override the inferred track type (e.g. `"AlignmentsTrack"`).
#' @param adapter_type Override the inferred adapter type.
#' @param track_id A unique id for the track. Defaults to `name`.
#' @param assembly_names Assembly name(s) the track belongs to. Usually left
#'   `NULL` — [JBrowseR()] backfills it from the loaded assembly.
#' @param index URL of the index file when it isn't the conventional sibling of
#'   `url` (`.bai`/`.crai`/`.tbi`). A `.csi` index is detected by extension.
#' @param ... Extra config merged into the track (e.g. `category = list("Genes")`).
#'
#' @return a track config list
#' @export
#'
#' @examples
#' track("https://jbrowse.org/genomes/hg19/gencode.v19.sorted.gff.gz", name = "Genes")
track <- function(url, name = NULL, type = NULL, adapter_type = NULL,
                  track_id = NULL, assembly_names = NULL, index = NULL, ...) {
  detected <- detect_track(url)
  name <- name %||% base_name(url)
  adapter <- build_adapter(url, index, detected)
  if (!is.null(adapter_type)) {
    adapter$type <- adapter_type
  }

  out <- list(
    type = type %||% detected$track,
    trackId = track_id %||% name,
    name = name,
    adapter = adapter
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

# Expand a JBrowseR() tracks entry into a full track config. A bare URL string
# runs through track(); a c(url, index) pair names a non-sibling index; a list
# (a track config from track() or written by hand) passes through untouched.
normalize_track <- function(entry) {
  if (is.character(entry)) {
    if (length(entry) == 2) {
      track(entry[[1]], index = entry[[2]])
    } else {
      track(entry[[1]])
    }
  } else {
    entry
  }
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

# extension -> track type, adapter type, longhand location slot, and how an
# explicit index attaches: "BAI"/"TBI" fill an `index` slot (default type,
# "CSI" for a .csi file), "crai" fills craiLocation, NA means no index file.
# The tabix formats (gff/gtf/bed/vcf) resolve to their indexed adapter when the
# url is bgzipped and to the plain whole-file adapter otherwise.
detect_track <- function(url) {
  clean <- sub("[?#].*$", "", url)
  bgzipped <- grepl("[.]gz$", clean, ignore.case = TRUE)
  ext <- tolower(sub(".*[.]", "", sub("[.]gz$", "", clean)))
  spec <- function(track, adapter, location, index) {
    list(track = track, adapter = adapter, location = location, index = index)
  }
  plain <- switch(ext,
    vcf = spec("VariantTrack", "VcfAdapter", "vcfLocation", NA),
    gff = spec("FeatureTrack", "Gff3Adapter", "gffLocation", NA),
    gff3 = spec("FeatureTrack", "Gff3Adapter", "gffLocation", NA),
    gtf = spec("FeatureTrack", "GtfAdapter", "gtfLocation", NA),
    bed = spec("FeatureTrack", "BedAdapter", "bedLocation", NA),
    NULL
  )
  if (!bgzipped && !is.null(plain)) {
    plain
  } else {
    switch(ext,
      bam = spec("AlignmentsTrack", "BamAdapter", "bamLocation", "BAI"),
      cram = spec("AlignmentsTrack", "CramAdapter", "cramLocation", "crai"),
      vcf = spec("VariantTrack", "VcfTabixAdapter", "vcfGzLocation", "TBI"),
      gff = spec("FeatureTrack", "Gff3TabixAdapter", "gffGzLocation", "TBI"),
      gff3 = spec("FeatureTrack", "Gff3TabixAdapter", "gffGzLocation", "TBI"),
      gtf = spec("FeatureTrack", "GtfTabixAdapter", "gtfGzLocation", "TBI"),
      bed = spec("FeatureTrack", "BedTabixAdapter", "bedGzLocation", "TBI"),
      bb = spec("FeatureTrack", "BigBedAdapter", "bigBedLocation", NA),
      bigbed = spec("FeatureTrack", "BigBedAdapter", "bigBedLocation", NA),
      bw = spec("QuantitativeTrack", "BigWigAdapter", "bigWigLocation", NA),
      bigwig = spec("QuantitativeTrack", "BigWigAdapter", "bigWigLocation", NA),
      hic = spec("HicTrack", "HicAdapter", "hicLocation", NA),
      stop(
        sprintf(
          "could not infer a track type from '%s'; pass type= and adapter_type=",
          url
        ),
        call. = FALSE
      )
    )
  }
}

# (url + optional index) -> adapter config. With no index, JBrowse's own `uri`
# shorthand derives the index sibling itself; an explicit index needs the
# longhand slots because that shorthand rebuilds (and would clobber) the index
# from `uri`.
build_adapter <- function(url, index, detected) {
  if (is.null(index)) {
    list(type = detected$adapter, uri = url)
  } else if (is.na(detected$index)) {
    stop(
      sprintf("%s ('%s') has no index file; drop index=", detected$adapter, url),
      call. = FALSE
    )
  } else {
    adapter <- list(type = detected$adapter)
    adapter[[detected$location]] <- list(uri = url)
    if (identical(detected$index, "crai")) {
      adapter$craiLocation <- list(uri = index)
    } else {
      index_type <- if (grepl("[.]csi$", tolower(index))) "CSI" else detected$index
      adapter$index <- list(location = list(uri = index), indexType = index_type)
    }
    adapter
  }
}
