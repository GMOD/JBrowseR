get_name <- function(string) {
  if (is_url(string)) {
    # get assembly name from URL
    name <- parse_url_name(string)
  } else {
    # get assembly name from file
    name <- parse_file_name(string)
  }
}

is_url <- function(string) {
  grepl("www.|http:|https:", string)
}

parse_url_name <- function(url) {
  stringr::str_split(url, "/", simplify = TRUE) %>%
    last_value() %>%
    stringr::str_split("[.]", simplify = TRUE) %>%
    first_value()
}

parse_file_name <- function(path) {
  stringr::str_split(basename(path), "[.]", simplify = TRUE) %>%
    first_value()
}

last_value <- function(x) {
  x[length(x)]
}

first_value <- function(x) {
  x[1]
}
