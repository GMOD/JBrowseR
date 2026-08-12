# Files on this machine, shipped into the browser as bytes rather than served
# over HTTP. See the `local_files` argument of JBrowseR()/JBrowseRApp().
#
# The wire format is the one jsonlite already gives us: a `raw` vector
# serializes to a base64 string, and htmlwidgets unboxes it, so the payload
# carries `localFiles: { "<name>": "<base64>" }` with no encoding step here.
# `srcjs/widget.ts` decodes it back to bytes.

# Index files an adapter asks for by deriving the name from its data file's, so
# registering one under `<name><suffix>` is what keeps an indexed file indexed.
INDEX_SUFFIXES <- c(".tbi", ".csi", ".bai", ".crai", ".fai", ".gzi")

# Warn before writing a document nobody can open. Base64 costs a third on top,
# and the result is embedded in the HTML (or sent over Shiny's websocket), so
# this is the size of the page rather than of a request the browser can stream.
SIZE_WARN_BYTES <- 50 * 1024^2

# `x` is a path, a character vector of paths, or a list mixing paths with raw
# vectors of bytes you already hold. Names override the registered name; without
# one a path registers under its basename, which is what a track config then
# refers to.
read_local_files <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  if (is.character(x)) {
    x <- as.list(x)
  }
  if (!is.list(x)) {
    stop("`local_files` must be file paths, or a list of paths and raw vectors",
      call. = FALSE
    )
  }
  names(x) <- names(x) %||% rep("", length(x))
  out <- list()
  for (i in seq_along(x)) {
    entry <- x[[i]]
    given <- names(x)[[i]]
    if (is.raw(entry)) {
      if (!nzchar(given)) {
        stop("a raw vector in `local_files` needs a name to be referred to by",
          call. = FALSE
        )
      }
      out <- add_local_file(out, given, entry)
    } else if (is.character(entry) && length(entry) == 1) {
      out <- read_local_file(out, entry, given)
    } else {
      stop("`local_files[[", i, "]]` must be a file path or a raw vector",
        call. = FALSE
      )
    }
  }
  total <- sum(vapply(out, length, numeric(1)))
  if (total > SIZE_WARN_BYTES) {
    warning(
      "local_files holds ", format_bytes(total), ", which travels base64-encoded ",
      "inside the document rather than as a request the browser can stream. ",
      "Serve files this size over HTTP and pass their URLs instead.",
      call. = FALSE
    )
  }
  out
}

# one path, plus any conventional sibling index next to it
read_local_file <- function(out, path, given) {
  if (!file.exists(path)) {
    stop("`local_files` file does not exist: ", path, call. = FALSE)
  }
  name <- if (nzchar(given)) given else basename(path)
  out <- add_local_file(out, name, read_bytes(path))
  for (suffix in INDEX_SUFFIXES) {
    index <- paste0(path, suffix)
    if (file.exists(index)) {
      out <- add_local_file(out, paste0(name, suffix), read_bytes(index))
    }
  }
  out
}

# Registering twice under one name is a mistake with no good reading — one of
# the two files would silently never be seen — so it stops rather than picking.
add_local_file <- function(out, name, bytes) {
  if (!is.null(out[[name]])) {
    stop("`local_files` has two entries named \"", name, "\"", call. = FALSE)
  }
  out[[name]] <- bytes
  out
}

read_bytes <- function(path) {
  readBin(path, "raw", n = file.info(path)$size)
}

format_bytes <- function(n) {
  paste(format(round(n / 1024^2, 1), trim = TRUE), "MB")
}
