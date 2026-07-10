#!/usr/bin/env Rscript

# Generate self-contained HTML pages with a *live, fully interactive* embedded
# JBrowse — the widget's whole JS bundle is inlined, so each page works offline
# (it still fetches track data from the URLs at view time). These are NOT shipped
# as package vignettes: the bundle is ~5 MB, well over CRAN's vignette budget, so
# the `JBrowseR.Rmd` vignette uses static screenshots instead. Run this to
# produce browsable demos for the website or a release.
#
#   Rscript tools/live_demo.R [output_dir]

out_dir <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(out_dir)) {
  out_dir <- "live-demos"
}
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

devtools::load_all(".", quiet = TRUE)

save_demo <- function(widget, file) {
  path <- file.path(out_dir, file)
  htmlwidgets::saveWidget(widget, path, selfcontained = TRUE)
  message(sprintf("%s (%.1f MB)", path, file.info(path)$size / 1e6))
}

# a hosted genome hub: assembly, gene search, and a RefSeq gene track
save_demo(
  JBrowseR(
    "hg38",
    tracks = tracks(track(
      paste0(
        "https://s3.amazonaws.com/jbrowse.org/genomes/GRCh38/ncbi_refseq/",
        "GCA_000001405.15_GRCh38_full_analysis_set.refseq_annotation.sorted.gff.gz"
      ),
      name = "NCBI RefSeq Genes"
    )),
    location = "BRCA1"
  ),
  "hub_genes.html"
)

# a custom genome straight from a FASTA URL (no assembly() call) with a bare
# data-URL alignments track the view infers
save_demo(
  JBrowseR(
    "https://jbrowse.org/genomes/volvox/volvox.fa",
    tracks = list("https://jbrowse.org/genomes/volvox/volvox.bam"),
    location = "ctgA:1..5,000"
  ),
  "custom_fasta.html"
)

# a comparative (synteny) browser via the full-app widget: two assemblies tied
# together by a PAF track
local({
  base <- "https://jbrowse.org/code/jb2/main/test_data/volvox/"
  save_demo(
    JBrowseRApp(
      assemblies = list(
        assembly(paste0(base, "volvox.2bit"), name = "volvox"),
        assembly(paste0(base, "volvox_del.fa"), name = "volvox_del")
      ),
      tracks = list(
        synteny_track(paste0(base, "volvox_del.paf"), "volvox", "volvox_del",
          track_id = "volvox_del_paf")
      ),
      views = list(
        synteny_view(c("volvox", "volvox_del"), tracks = "volvox_del_paf")
      )
    ),
    "synteny.html"
  )
})
