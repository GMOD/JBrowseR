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

# `demos` carries every single-purpose app as a tab, so one hosted app covers
# all of them — shinyapps.io's free plan allows five and a sixth returns HTTP
# 402, which no longer forces a choice about which demos to leave out. The
# individual apps stay in the repo to read and copy, and can be named on the
# command line to host as well.
hosted <- "demos"
all_apps <- c(
  hosted,
  "basic_usage_with_text_index",
  "bookmarks_demo",
  "interactive_peak_calling",
  "load_config_json",
  "load_data_frame",
  "skbr3_gene_fusions",
  "using_plugins"
)

args <- setdiff(commandArgs(trailingOnly = TRUE), "all")
apps <- if (length(args) > 0) args else hosted
unknown <- setdiff(apps, all_apps)
if (length(unknown) > 0) {
  stop("no such app: ", paste(unknown, collapse = ", "), call. = FALSE)
}

# One app failing shouldn't strand the rest — an account over its plan's app
# limit fails only on the ones past it — so keep going and report at the end.
# forceUpdate because redeploying over an existing app is the whole point here,
# and the prompt rsconnect would otherwise raise has nobody to answer it in CI.
# A deploy that fails while the server builds the image still leaves the app
# registered and holding one of the plan's slots, so SHINYAPPS_PRUNE=true clears
# anything on the account that isn't being deployed now.
if (identical(Sys.getenv("SHINYAPPS_PRUNE"), "true")) {
  # already-terminated apps stay in the listing and terminating one again is an
  # error ("Invalid status: terminated"), so go by status rather than presence
  existing <- applications(account = account)
  live <- existing$name[existing$status != "terminated"]
  for (app in setdiff(live, apps)) {
    message("terminating ", app)
    terminateApp(app, account = account)
  }
}

failed <- character(0)
for (app in apps) {
  ok <- tryCatch(
    {
      deployApp(
        file.path("example_apps", app),
        appName = app,
        account = account,
        forceUpdate = TRUE
      )
      TRUE
    },
    error = function(e) {
      message(sprintf("FAILED %s: %s", app, conditionMessage(e)))
      FALSE
    }
  )
  if (ok) {
    message(sprintf("deployed https://%s.shinyapps.io/%s/", account, app))
  } else {
    failed <- c(failed, app)
  }
}

if (length(failed) > 0) {
  stop("failed to deploy: ", paste(failed, collapse = ", "), call. = FALSE)
}

## install.packages(c('JBrowseR', 'crosstalk', 'DT', 'rsconnect'))
