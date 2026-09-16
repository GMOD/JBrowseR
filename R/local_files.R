# jsonlite serializes a raw vector as base64, which srcjs/widget.ts decodes

INDEX_SUFFIXES <- c(".tbi", ".csi", ".bai", ".crai", ".fai", ".gzi")

# the bytes ride base64-encoded inside the page, not as a streamable request
SIZE_WARN_BYTES <- 50 * 1024^2

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
