#!/usr/bin/env Rscript

# Deploy the example apps to https://gmod.shinyapps.io/<app>/. Run from the repo
# root; example_apps/README.md lists each one with its live URL.
#
# Install JBrowseR from GitHub first, not from a local build:
#
#   remotes::install_github("GMOD/JBrowseR")
#
# rsconnect reinstalls every dependency on the server from where the local copy
# came, and a devtools::install'd package records no remote to fetch — so it
# falls back to the CRAN release, which is a different API. Installing from
# GitHub records the remote, so what deploys matches this checkout.

library(rsconnect)

apps <- c(
  "basic_usage_with_text_index",
  "bookmarks_demo",
  "interactive_peak_calling",
  "load_config_json",
  "load_data_frame",
  "skbr3_gene_fusions",
  "using_plugins"
)

for (app in apps) {
  deployApp(file.path("example_apps", app), appName = app, account = "gmod")
}

## install.packages(c('JBrowseR', 'crosstalk', 'DT', 'rsconnect'))
