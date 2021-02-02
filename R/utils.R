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

# get the name out of the assembly config string
get_assembly_name <- function(assembly) {
  name_entry <- stringr::str_split(assembly, ",")[[1]][1]
  stringr::str_split(name_entry, "\"")[[1]][4]
}

# get the assembly adapter out of the assembly config string
get_assembly_adapter <- function(assembly) {
  assembly_vector <- stringr::str_split(assembly, ",")[[1]]
  adapter <- assembly_vector[4:length(assembly_vector)]
  adapter_string <- as.character(
    stringr::str_flatten(adapter, ", ")
  )
  # return without the adapter field in front
  stringr::str_trim(stringr::str_remove(adapter_string, '"adapter":'))
}
