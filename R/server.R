#' Serve a local data directory for use with a browser
#'
#' @param path The path to the directory with data to serve
#' @param port The port to serve the directory on
#'
#' @export
#'
#' @examples
#' \dontrun{
#'   server <- serve_data("~/path/to/my-data")
#'   # use server$stop_server() to stop
#' }
serve_data <- function(path, port = 5000) {
  path <- normalizePath(path, mustWork = TRUE)

  if (path != ".") {
    # clean up R directory after exit if not current directory
    original_dir <- setwd(path)
    on.exit(setwd(original_dir))
  }

  server <- create_server(path, port)
  app <- list(call = serve_directory(path))
  server$start_server(app)
  invisible(server)
}

create_server <- function(path, port) {
  host <- "127.0.0.1"
  server <- NULL
  list(
    host = host,
    port = as.integer(port),
    interval = 1,
    url = sprintf("http://%s:%d", "127.0.0.1", as.integer(port)),
    start_server = function(app) {
      server_id <- httpuv::startServer(host, port, app)
      server <<- server_id
      invisible(server_id)
    },
    stop_server = function() {
      if (is.null(server)) {
        stop("The server has not been started.")
      } else {
        httpuv::stopServer(server)
      }
    }
  )
}

serve_directory <- function(path) {
  function(req) {
    original_dir <- setwd(path)
    on.exit(setwd(original_dir))
    req_path <- resolve_req_path(req)

    # response content
    if (is.null(req$HTTP_RANGE)) {
      status <- 200L
    } else {
      status <- 206L
      range <- parse_range(req$HTTP_RANGE, req_path)
    }
    type <- guess_type(path)
    body <- generate_body(req, req_path)
    if (is.character(body) && length(body) > 1) {
      body <- paste2(body)
    }
    headers <- c(
      list(
        "Access-Control-Allow-Origin" = "*",
        "Access-Control-Allow-Headers" = "range, Origin, Content-Type",
        "Access-Control-Expose-Headers" = "Content-Length,Content-Range",
        "Content-Type" = type
      ), if (status == 206L) {
        list(
          "Content-Range" = paste0(
            "bytes ",
            range[2],
            "-",
            range[3],
            "/",
            file.info(req_path)[, "size"]
          )
        )
      },
      "Accept-Ranges" = "bytes"
    )

    list(
      status = status,
      body = body,
      headers = headers
    )
  }
}

resolve_req_path <- function(req) {
  req_path <- httpuv::decodeURIComponent(req$PATH_INFO)
  Encoding(req_path) <- "UTF-8"

  if (grepl("^/", req_path)) {
    stringr::str_c(".", req_path)
  } else if (req_path == "") {
    "."
  }
}

generate_body <- function(req, req_path) {
  range <- req$HTTP_RANGE

  if (is.null(range)) {
    read_raw(req_path)
  } else {
    range <- parse_range(range, req_path)
    byte2 <- as.numeric(range[2])
    byte3 <- as.numeric(range[3])

    if (length(range) < 3 || (range[1] != "bytes") || (byte2 >= byte3)) {
      return(
        list(
          status = 416L, headers = list("Content-Type" = "text/plain"),
          body = "Requested range not satisfiable\r\n"
        )
      )
    }

    connection <- file(req_path, open = "rb", raw = TRUE)
    on.exit(close(connection))
    seek(connection, where = byte2, origin = "start")
    readBin(connection, "raw", byte3 - byte2 + 1)
  }
}

read_raw <- function(req_path) {
  readBin(
    req_path,
    "raw",
    file.info(req_path)[, "size"]
  )
}

guess_type <- function(path) {
  mimetype = function(...) {
    system2('mimetype', c('-b', shQuote(path)), ...)
  }
  if (Sys.which('mimetype') == '' || mimetype(stdout = NULL) != 0)
    return(mime::guess_type(path))
  mimetype(stdout = TRUE)
}

parse_range <- function(range, req_path) {
  range <- strsplit(range, split = "(=|-)")[[1]]
  if (length(range) == 2 && range[1] == "bytes") {
    # open-end range request
    range[3] <- file.info(req_path)[, "size"] - 1
  }
  range
}


# Notes: ------------------------------------------------------------------

# This is a small static HTTP server for local files

# It is heavily inspired by the static server in the {servr} package by
# Yihui Xie

# There are two crucial requirements for serving data to JBrowse 2:

# 1. CORS must be enabled. See headers for more info.
# 2. Must support range requests
