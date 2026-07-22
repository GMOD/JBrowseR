# Build every example widget with the real JBrowseR API and dump each
# htmlwidget's payload (w$x) to tools/screenshot_specs.json, for
# tools/screenshot_examples.mjs to render headless. Names match the figures the
# README and the intro vignette reference, so a regen refreshes all of them from
# the current bundle. Run:  Rscript tools/gen_screenshot_specs.R
suppressMessages(library(JBrowseR))
library(jsonlite)

spec <- function(bundle, caption, x) list(bundle = bundle, caption = caption, x = x)
# the common single-view case: name the figure, build a JBrowseR() widget, keep $x
lgv <- function(caption, ...) spec("JBrowseR.js", caption, JBrowseR(...)$x)

refseq_gff <- paste0(
  "https://jbrowse.org/genomes/GRCh38/ncbi_refseq/",
  "GCA_000001405.15_GRCh38_full_analysis_set.refseq_annotation.sorted.gff.gz"
)
phylop_bw <- "https://hgdownload.soe.ucsc.edu/goldenPath/hg38/phyloP100way/hg38.phyloP100way.bw"

set.seed(1)
peaks <- data.frame(
  chrom = "17",
  start = seq(43000000, 43120000, by = 12000),
  end = seq(43000000, 43120000, by = 12000) + 4000,
  name = paste0("peak", 1:11),
  score = round(runif(11, 5, 100))
)

specs <- list(
  "demo-alignments" = lgv(
    "NA12878 exome CRAM on hg38",
    "hg38",
    tracks = tracks(track(
      paste0(
        "https://jbrowse.org/genomes/GRCh38/alignments/NA12878/",
        "NA12878.alt_bwamem_GRCh38DH.20150826.CEU.exome.cram"
      ),
      name = "NA12878 Exome"
    )),
    location = "17:43,044,295..43,048,000"
  ),
  "demo-genes" = lgv(
    "NCBI RefSeq genes at BRCA1",
    "hg38",
    tracks = tracks(track(refseq_gff, name = "NCBI RefSeq Genes")),
    location = "BRCA1"
  ),
  "demo-variants" = lgv(
    "1000 Genomes variants",
    "hg38",
    tracks = tracks(track(
      paste0(
        "https://jbrowse.org/genomes/GRCh38/variants/",
        "ALL.wgs.shapeit2_integrated_snvindels_v2a.GRCh38.27022019.sites.vcf.gz"
      ),
      name = "1000 Genomes Variants"
    )),
    location = "17:43,045,000..43,046,800"
  ),
  "demo-conservation" = lgv(
    "phyloP100way conservation bigWig",
    "hg38",
    tracks = tracks(track(phylop_bw, name = "phyloP100way Conservation")),
    location = "17:43,044,295..43,048,000"
  ),
  "demo-dataframe" = lgv(
    "R data.frame of peaks -> track",
    "hg38",
    tracks = list(track_data_frame(peaks, "R_peaks")),
    location = "17:43,000,000..43,125,000"
  ),
  "demo-skbr3" = lgv(
    "SKBR3 long-read structural variants",
    "hg19",
    tracks = tracks(
      track(
        paste0(
          "https://jbrowse.org/genomes/hg19/SKBR3/",
          "reads_lr_skbr3.fa_ngmlr-0.2.3_mapped.bam.sniffles1kb_auto_l8_s5_noalt.filtered.vcf.gz"
        ),
        name = "Sniffles SV calls"
      ),
      track(
        paste0(
          "https://jbrowse.org/genomes/hg19/skbr3/",
          "reads_lr_skbr3.fa_ngmlr-0.2.3_mapped.down.bam"
        ),
        name = "SKBR3 PacBio long reads"
      )
    ),
    # the one Sniffles call on chr17: a translocation to chr20 at 65,445,795;
    # a tight window here shows the reads clipping at the breakpoint
    location = "17:65,440,000..65,451,000"
  ),
  "demo-cancer-deletion" = lgv(
    "HG008-T PacBio HiFi somatic deletion at CUZD1",
    "hg38",
    tracks = tracks(track(
      "https://jbrowse.org/demos/cgiab/HG008-T_chr10_CUZD1_deletion.bam",
      name = "HG008-T PacBio HiFi"
    )),
    location = "10:122,822,000..122,851,000"
  ),
  # a track's *display* can plot its data: a GWASTrack with a
  # LinearManhattanDisplay draws summary statistics in the linear view
  "demo-manhattan" = lgv(
    "GWAS summary stats as a Manhattan plot",
    "hg19",
    tracks = list(list(
      type = "GWASTrack",
      trackId = "gwas_track",
      name = "GWAS",
      adapter = list(
        type = "GWASAdapter",
        scoreColumn = "neg_log_pvalue",
        uri = "https://jbrowse.org/genomes/hg19/gwas/summary_stats.txt.gz"
      ),
      displays = list(list(type = "LinearManhattanDisplay", height = 250))
    )),
    location = "2"
  ),
  "demo-theme" = lgv(
    "custom-themed browser",
    "hg38",
    tracks = tracks(track(refseq_gff, name = "NCBI RefSeq Genes")),
    theme = theme("#311b92", "#0097a7"),
    location = "BRCA1"
  )
)

# comparative synteny uses the full app (JBrowseRApp / app.jsx bundle)
base <- "https://jbrowse.org/demos/ecoli_pangenome"
strains <- c("K12", "Sakai", "CFT073", "NCTC86")
# the flat { name, uri } assembly shorthand core expands itself — no helper
assemblies <- lapply(strains, function(s) {
  list(name = s, uri = paste0(base, "/", s, ".fa.gz"))
})
ecoli_ava <- list(
  type = "SyntenyTrack",
  trackId = "ecoli_ava",
  name = "E. coli all-vs-all (minimap2 PAF)",
  assemblyNames = as.list(strains),
  adapter = list(
    type = "AllVsAllPAFAdapter",
    assemblyNames = as.list(strains),
    pafLocation = list(uri = paste0(base, "/all_vs_all.paf.gz"))
  )
)
specs[["demo-synteny"]] <- spec(
  "JBrowseRApp.js",
  "four E. coli strains (synteny)",
  JBrowseRApp(
    assemblies = assemblies,
    tracks = list(ecoli_ava),
    views = list(
      synteny_view(
        as.list(strains),
        tracks = list(list("ecoli_ava"), list("ecoli_ava"), list("ecoli_ava")),
        drawCurves = FALSE,
        minAlignmentLength = 10000
      )
    )
  )$x
)

specs[["demo-dotplot"]] <- spec(
  "JBrowseRApp.js",
  "the same PAF as a whole-genome dotplot",
  JBrowseRApp(
    assemblies = assemblies[1:2],
    tracks = list(ecoli_ava),
    views = list(dotplot_view(list("K12", "Sakai"), tracks = list("ecoli_ava")))
  )$x
)

writeLines(
  toJSON(specs, auto_unbox = TRUE, null = "null", pretty = TRUE),
  "tools/screenshot_specs.json"
)
cat("wrote tools/screenshot_specs.json:", paste(names(specs), collapse = ", "), "\n")
