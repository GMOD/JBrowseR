# The vignettes set eval = FALSE and the notebooks run only on Colab, so their R
# is parsed here rather than run: the notebooks called helpers deleted in
# d9ef6d5 for six weeks with nothing failing.

repo <- test_path("..", "..")

doc_chunks <- function() {
  rmds <- c(
    file.path(repo, "README.Rmd"),
    list.files(file.path(repo, "vignettes"), "[.]Rmd$", full.names = TRUE, recursive = TRUE)
  )
  from_rmd <- lapply(rmds, function(path) {
    lines <- readLines(path, warn = FALSE)
    opens <- grep("^```\\s*(\\{r[ ,}]|r\\s*$)", lines)
    closes <- grep("^```\\s*$", lines)
    lapply(opens, function(open) {
      close <- closes[closes > open][1]
      list(
        where = path, offset = open,
        code = lines[seq_len(close - open - 1) + open]
      )
    })
  })
  notebooks <- list.files(file.path(repo, "examples"), "[.]ipynb$", full.names = TRUE)
  from_ipynb <- lapply(notebooks, function(path) {
    cells <- jsonlite::fromJSON(path, simplifyVector = FALSE)$cells
    code <- Filter(function(cell) cell$cell_type == "code", cells)
    lapply(seq_along(code), function(i) {
      list(
        where = paste0(path, " code cell ", i), offset = 0,
        code = strsplit(paste(unlist(code[[i]]$source), collapse = ""), "\n")[[1]]
      )
    })
  })
  split(
    c(unlist(from_rmd, recursive = FALSE), unlist(from_ipynb, recursive = FALSE)),
    c(
      rep(rmds, lengths(from_rmd)),
      rep(notebooks, lengths(from_ipynb))
    )
  )
}

package_exports <- function(pkgs) {
  unlist(lapply(pkgs, function(pkg) {
    if (requireNamespace(pkg, quietly = TRUE)) getNamespaceExports(pkg)
  }))
}

description_packages <- function(field) {
  deps <- read.dcf(file.path(repo, "DESCRIPTION"), fields = field)[1, 1]
  pkgs <- trimws(sub("\\(.*", "", strsplit(deps, ",")[[1]]))
  setdiff(pkgs[nzchar(pkgs)], "R")
}

known_functions <- function() {
  base <- rownames(utils::installed.packages(priority = c("base", "recommended")))
  unique(c(
    package_exports(c(base, description_packages(c("Imports")), description_packages("Suggests"))),
    ls(baseenv(), all.names = TRUE),
    # IRkernel's, on Colab
    "display_html"
  ))
}

jbrowser_exports <- function() {
  ns <- readLines(file.path(repo, "NAMESPACE"))
  sub("^export\\((.*)\\)$", "\\1", grep("^export\\(", ns, value = TRUE))
}

# problems in one document, which shares definitions across its chunks
check_document <- function(chunks, known, exports) {
  parsed <- lapply(chunks, function(chunk) {
    pd <- utils::getParseData(parse(text = chunk$code, keep.source = TRUE))
    pd$where <- chunk$where
    pd$line <- pd$line1 + chunk$offset
    pd
  })
  assigned <- unique(unlist(lapply(parsed, function(pd) {
    arrows <- pd[pd$token %in% c("LEFT_ASSIGN", "EQ_ASSIGN"), ]
    lhs <- pd[pd$parent %in% arrows$parent & pd$token == "expr", ]
    pd$text[pd$parent %in% lhs$id & pd$token == "SYMBOL"]
  })))

  problems <- character()
  flag <- function(row, msg) {
    where <- sub("^(.*/)?[.][.]/[.][.]/", "", row$where)
    problems <<- c(problems, sprintf("%s:%d: %s", where, row$line, msg))
  }
  for (pd in parsed) {
    for (i in which(pd$token == "SYMBOL_FUNCTION_CALL")) {
      row <- pd[i, ]
      siblings <- pd[pd$parent == row$parent, ]
      if (any(siblings$token %in% c("'$'", "'@'"))) next
      fn <- row$text
      pkg <- siblings$text[siblings$token == "SYMBOL_PACKAGE"]
      if (length(pkg) && pkg == "JBrowseR" && !fn %in% exports) {
        flag(row, paste0("JBrowseR does not export ", fn, "()"))
      } else if (!length(pkg) && !fn %in% c(exports, assigned, known)) {
        flag(row, paste0(fn, "() is not exported by JBrowseR or an allowed package"))
      }
      call <- pd[pd$id == pd$parent[pd$id == row$parent], ]
      args <- pd[pd$parent == call$id & pd$token == "SYMBOL_SUB", ]
      if (fn %in% exports && (!length(pkg) || pkg == "JBrowseR")) {
        formal <- names(formals(getExportedValue("JBrowseR", fn)))
        if (!"..." %in% formal) {
          for (j in which(!args$text %in% formal)) {
            flag(args[j, ], paste0(fn, "() has no argument `", args$text[j], "`"))
          }
        }
      }
      if (fn == "list" && all(c("type", "init") %in% args$text)) {
        flag(args[args$text == "init", ], "a view nests its settings under `init`; write them beside `type`")
      }
    }
  }
  problems
}

test_that("documented R calls only what the package and its dependencies export", {
  skip_if_not(file.exists(file.path(repo, "README.Rmd")), "docs are not in a built package")
  known <- known_functions()
  exports <- jbrowser_exports()
  problems <- unlist(lapply(unname(doc_chunks()), check_document, known = known, exports = exports))
  expect(length(problems) == 0, paste(c("the docs have drifted:", problems), collapse = "\n"))
})
