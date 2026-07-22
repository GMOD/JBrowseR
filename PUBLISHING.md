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

## A server-free alternative (shinylive)

[shinylive](https://posit-dev.github.io/r-shinylive/) compiles a Shiny app to
WebAssembly, so the example apps could be served straight from the pkgdown site
with no shinyapps.io account and nothing to keep running.

webR cannot install from source, so `remotes::install_github()` does not work
there — packages have to be pre-compiled Wasm binaries. `shinylive::export()`
takes them from https://repo.r-wasm.org, which mirrors CRAN (JBrowseR, shiny and
htmlwidgets are all present), so out of the box a shinylive demo runs the CRAN
release rather than this checkout.

That is not a hard limit, just a build step. [rwasm](https://r-wasm.github.io/rwasm/)
compiles Wasm binaries from any [pkgdepends
reference](https://r-lib.github.io/pkgdepends/reference/pkg_refs.html), GitHub
included:

```r
rwasm::add_pkg("GMOD/JBrowseR")   # or "GMOD/JBrowseR@branch", "GMOD/JBrowseR#42"
rwasm::write_packages()
```

It needs the Emscripten toolchain, which the webR project ships as a Docker
container. Host the resulting CRAN-like directory (GitHub Pages will do) and the
app installs from it before loading the library:

```r
webr::install("JBrowseR", repos = "https://<your-wasm-repo>/")
library(JBrowseR)
```

`shinylive::export()` has no argument for a custom repository, so that
`webr::install()` call in the app is the documented way in.
