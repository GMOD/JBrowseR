#!/usr/bin/env Rscript

# Deploy the example apps to https://<account>.shinyapps.io/<app>/. Run from the
# repo root; example_apps/README.md lists each one with its live URL.
#
# The account is SHINYAPPS_NAME, defaulting to the one the demos are published
# under. Setting SHINYAPPS_TOKEN/SHINYAPPS_SECRET as well registers the account
# first, which is how .github/workflows/shinyapps.yaml runs unattended; locally,
# leave them unset and use the account rsconnect already has.
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

# The manifest rsconnect uploads names, per package, the repo it came from, and
# the shinyapps build server fetches sources from there — so every dependency has
# to have been installed from a repo that server can reach. A session configured
# for Posit Package Manager under the name RSPM fails on the server with
# `Unsupported url scheme: RSPM/src/contrib/...`; the name has to resolve here.
options(repos = c(CRAN = "https://cloud.r-project.org"))

account <- Sys.getenv("SHINYAPPS_NAME", "jbrowse")
token <- Sys.getenv("SHINYAPPS_TOKEN")
secret <- Sys.getenv("SHINYAPPS_SECRET")
if (nzchar(token) && nzchar(secret)) {
  setAccountInfo(name = account, token = token, secret = secret)
}

all_apps <- c(
  "basic_usage_with_text_index",
  "bookmarks_demo",
  "interactive_peak_calling",
  "load_config_json",
  "load_data_frame",
  "skbr3_gene_fusions",
  "using_plugins"
)

# name apps on the command line to deploy a subset — shinyapps.io plans cap how
# many apps an account may host, so all seven is not always what you want
args <- setdiff(commandArgs(trailingOnly = TRUE), "all")
apps <- if (length(args) > 0) args else all_apps
unknown <- setdiff(apps, all_apps)
if (length(unknown) > 0) {
  stop("no such app: ", paste(unknown, collapse = ", "), call. = FALSE)
}

for (app in apps) {
  deployApp(file.path("example_apps", app), appName = app, account = account)
  message(sprintf("https://%s.shinyapps.io/%s/", account, app))
}

## install.packages(c('JBrowseR', 'crosstalk', 'DT', 'rsconnect'))
