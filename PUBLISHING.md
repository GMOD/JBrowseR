Make sure you have role c("aut","cre") in the JBrowseR DESCRIPTION file or else
add yourself and make it so. Then run steps similar to the following

```

git clone git@github.com:GMOD/JBrowseR
cd JBrowseR

>> manually update DESCRIPTION with new version number to be used, and NEWS.md with changelog

# get latest @jbrowse/react-linear-genome-view, repo has a normal package.json
# and yarn.lock
yarn upgrade

# runs webpack
yarn build


# commit built artifacts
git add .
git commit -m "Update deps"

# start R session
R
> install.packages(devtools)
> devtools::submit_cran()

```

## After a CRAN release

Redeploy the hosted Shiny apps so they match the release:

```
R -e 'remotes::install_github("GMOD/JBrowseR")'   # see the note in example_apps/deploy.R
Rscript example_apps/deploy.R
```

A server-free option becomes available at the same moment:
[shinylive](https://posit-dev.github.io/r-shinylive/) compiles a Shiny app to
WebAssembly, so the example apps could be served straight from the pkgdown site
with no shinyapps.io account and nothing to keep running. It installs packages
from the webR binary repo, which mirrors CRAN — JBrowseR, shiny and htmlwidgets
are all there — so a shinylive demo tracks the CRAN version, not this checkout.
