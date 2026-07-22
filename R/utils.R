# base name of a file or URL, without directory or extensions
# "https://x/y/hg19.fa.gz" -> "hg19"
base_name <- function(x) {
  file <- basename(sub("[?#].*$", "", x))
  sub("[.].*$", "", file)
}

# a coalescing operator: `a %||% b` is `a` unless it is NULL. Defined here for
# R (>= 4.1); base R only gained `%||%` in 4.4.
`%||%` <- function(a, b) {
  if (is.null(a)) b else a
}

drop_null <- function(x) {
  x[!vapply(x, is.null, logical(1))]
}

# id vectors (trackIds, assemblyNames) must serialize as a JSON array even at
# length 1; NULL stays NULL so drop_null omits the field
as_json_array <- function(x) {
  if (is.null(x)) NULL else as.list(x)
}

# Every widget payload is createApp/createLinearGenomeView's options verbatim
# (camelCase): the `config` escape hatch is the base, `fields` the explicit
# arguments that override it, so both constructors share one createWidget call.
create_widget <- function(name, config, fields, width, height, elementId) {
  htmlwidgets::createWidget(
    name = name,
    x = utils::modifyList(as_config(config), drop_null(fields)),
    width = width,
    height = height,
    package = "JBrowseR",
    elementId = elementId,
    sizingPolicy = htmlwidgets::sizingPolicy(
      defaultWidth = "100%",
      viewer.fill = TRUE,
      browser.fill = TRUE
    )
  )
}

# a theme() config rides to the view as configuration = { theme }
configuration_from_theme <- function(theme) {
  if (is.null(theme)) NULL else list(theme = theme)
}

# accept a single text_index() adapter or a list of them; the view always wants
# the array (a single named adapter has $type, a list of adapters does not)
as_adapter_list <- function(x) {
  if (is.null(x) || is.null(x$type)) x else list(x)
}

# config escape hatch: a list passes through; a JSON string (e.g. read by hand)
# is parsed. It forms the payload base that explicit arguments override.
as_config <- function(config) {
  if (is.null(config)) {
    list()
  } else if (is.character(config)) {
    jsonlite::fromJSON(config, simplifyVector = FALSE)
  } else {
    config
  }
}
