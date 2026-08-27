# Dump the payload of every figure widget to tools/screenshot_specs.json, for
# tools/screenshot_examples.mjs to render headless.
#
# The payloads come from running the documents that show the figures, not from a
# second description of them here. A chunk's label IS its figure's name, so the
# `![...](../man/figures/demo-genes.png)` under a ```{r demo-genes} block is a
# picture of the code above it and cannot drift from it. This script used to
# restate each vignette's config alongside it, and the two agreed only while
# someone kept them agreeing.
#
# Executing them is also the only check that the documented code *runs*: the
# vignettes set `eval = FALSE`, so knitting never evaluates a line of it.
#
# Run:  Rscript tools/gen_screenshot_specs.R
suppressMessages(library(JBrowseR))
library(jsonlite)

DOCS <- c("vignettes/JBrowseR.Rmd", "vignettes/comparative-synteny.Rmd")

# Chunks in source order, as label/code pairs. Written out rather than taken
# from knitr because knit_code is cleared once purl() returns, and purl()'s file
# output has the labels only as comments.
chunks_of <- function(path) {
  lines <- readLines(path, warn = FALSE)
  opens <- grep("^```\\{r[ ,}]", lines)
  closes <- grep("^```\\s*$", lines)
  lapply(opens, function(open) {
    close <- closes[closes > open][1]
    list(
      label = sub("^```\\{r[ ,]*([^,}]*).*$", "\\1", lines[open]),
      code = lines[seq_len(max(close - open - 1, 0)) + open]
    )
  })
}

# Figures the prose points at. Every one of them must come out of a chunk below,
# so a label that goes missing fails the run rather than quietly shipping the
# last render of a figure nothing builds any more.
docs <- c(
  "README.Rmd",
  list.files("vignettes", "[.]Rmd$", full.names = TRUE, recursive = TRUE)
)
wanted <- unique(unlist(lapply(docs, function(path) {
  lines <- readLines(path, warn = FALSE)
  # [a-z0-9-] and not [a-z-]: `demo-skbr3` ends in a digit, and a name class
  # that stops before it matched nothing at all, so that figure silently left
  # the run — with the missing-chunk check below none the wiser
  regmatches(lines, regexpr("demo-[a-z0-9-]+(?=[.]png)", lines, perl = TRUE))
})))

specs <- list()
for (path in DOCS) {
  # one environment per document: a vignette stands alone, and chunks after the
  # first depend on the ones before (the assemblies list, the peaks data frame)
  env <- new.env(parent = globalenv())
  for (chunk in chunks_of(path)) {
    value <- eval(parse(text = chunk$code), env)
    if (chunk$label %in% wanted) {
      if (!inherits(value, "htmlwidget")) {
        stop("chunk `", chunk$label, "` in ", path, " built no widget", call. = FALSE)
      }
      # class(w)[1] is the widget name htmlwidgets dispatches on, which is also
      # the bundle's basename — the two are the same string by construction
      specs[[chunk$label]] <- list(
        bundle = paste0(class(value)[[1]], ".js"),
        x = value$x
      )
    }
  }
}

missing <- setdiff(wanted, names(specs))
if (length(missing) > 0) {
  stop(
    "no chunk builds: ", paste(missing, collapse = ", "),
    ". Label the chunk that shows each with its figure's name.",
    call. = FALSE
  )
}

writeLines(
  toJSON(specs, auto_unbox = TRUE, null = "null", pretty = TRUE),
  "tools/screenshot_specs.json"
)
cat("wrote tools/screenshot_specs.json:", paste(names(specs), collapse = ", "), "\n")
