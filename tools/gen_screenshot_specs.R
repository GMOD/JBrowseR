# Build example widgets with the real JBrowseR API and dump each htmlwidget's
# payload (w$x) to tools/screenshot_specs.json, for tools/screenshot_examples.mjs
# to render headless. Using the actual helpers keeps the README screenshots
# faithful to what users type. Run:  Rscript tools/gen_screenshot_specs.R
suppressMessages(library(JBrowseR))
library(jsonlite)

spec <- function(bundle, caption, x) list(bundle = bundle, caption = caption, x = x)

# 1. alignments — the README hero: 1000G NA12878 exome CRAM on the hg38 hub
cram <- paste0(
  "https://jbrowse.org/genomes/GRCh38/alignments/NA12878/",
  "NA12878.alt_bwamem_GRCh38DH.20150826.CEU.exome.cram"
)
aln <- JBrowseR(
  "hg38",
  tracks = tracks(track(cram, name = "NA12878 Exome")),
  location = "17:43,044,295..43,048,000"
)

# 2. data.frame -> track — results computed in R, no file written
set.seed(1)
peaks <- data.frame(
  chrom = "17",
  start = seq(43000000, 43120000, by = 12000),
  end = seq(43000000, 43120000, by = 12000) + 4000,
  name = paste0("peak", 1:11),
  score = round(runif(11, 5, 100))
)
df <- JBrowseR(
  "hg38",
  tracks = list(track_data_frame(peaks, "R_peaks")),
  location = "17:43,000,000..43,125,000"
)

# 3. synteny — four E. coli strains via JBrowseRApp (comparative-synteny.Rmd)
base <- "https://jbrowse.org/demos/ecoli_pangenome"
strains <- c("K12", "Sakai", "CFT073", "NCTC86")
assemblies <- lapply(strains, function(s) {
  assembly(paste0(base, "/", s, ".fa.gz"), name = s)
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
syn <- JBrowseRApp(
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
)

specs <- list(
  "demo-alignments" = spec("JBrowseR.js", "NA12878 exome CRAM on hg38", aln$x),
  "demo-dataframe" = spec("JBrowseR.js", "R data.frame of peaks -> track", df$x),
  "demo-synteny" = spec("JBrowseRApp.js", "four E. coli strains (synteny)", syn$x)
)
writeLines(
  toJSON(specs, auto_unbox = TRUE, null = "null", pretty = TRUE),
  "tools/screenshot_specs.json"
)
cat("wrote tools/screenshot_specs.json:", paste(names(specs), collapse = ", "), "\n")
