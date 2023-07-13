---
output: github_document
---

<!-- README.md is generated from README.Rmd. Please edit that file -->



# JBrowseR <img src='man/figures/logo.png' align="right" height="136" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/GMOD/JBrowseR/workflows/R-CMD-check/badge.svg)](https://github.com/gmod/JBrowseR/actions)
[![CRAN status](https://www.r-pkg.org/badges/version/JBrowseR)](https://CRAN.R-project.org/package=JBrowseR)
<!-- badges: end -->

JBrowseR is an R package that provides a simple and clean interface to [JBrowse 2](https://jbrowse.org/jb2/) for R users.
Using JBrowseR, you can:

- Embed the JBrowse 2 genome browser in **R Markdown** documents and **Shiny applications**
- Deploy a genome browser directly from the R console to view your data
- Customize your genome browser to display your own data


## Installation

You can install the released version of JBrowseR from [CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("JBrowseR")
```

And the development version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("gmod/JBrowseR")
```
## Example

This line of code can be used to launch a genome browser from your R console:


```r
library(JBrowseR)
JBrowseR("ViewHg19", location = "10:29,838,737..29,838,819")
```

<img src="man/figures/README-example-1.png" width="100%" />

## Getting started

In order to get started with JBrowseR, please refer to the vignette that best suits your needs:

- [Introduction](https://gmod.github.io/JBrowseR/articles/JBrowseR.html)
- [Custom browser tutorial](https://gmod.github.io/JBrowseR/articles/custom-browser-tutorial.html)
- [JSON configuration tutorial](https://gmod.github.io/JBrowseR/articles/json-tutorial.html)
- [Creating URLS](https://gmod.github.io/JBrowseR/articles/creating-urls.html)

## Live demos


### Basic usage including text search index

Allows you to search by gene name

https://gmod.shinyapps.io/basic_usage_with_text_index

### Multi purpose demo app

Shows a "bookmark" type feature, loading data from data frame, and buttons to navigate to genes of interest

https://gmod.shinyapps.io/bookmarks_demo

### Load config.json file

Shows loading a config.json file

https://gmod.shinyapps.io/load_config_json

### Load data frame

Simple example showing a data frame as a track

https://gmod.shinyapps.io/load_data_frame

### Gene fusion example

Shows putative gene fusions in the SKBR3 breast cancer cell line

https://gmod.shinyapps.io/skbr3_gene_fusions


## Citation

If you use JBrowseR in your research, please cite the following publication:

[Hershberg et al., 2021. JBrowseR: An R Interface to the JBrowse 2 Genome Browser](https://doi.org/10.1093/bioinformatics/btab459)

```
@article{hershberg2021jbrowser,
  title={JBrowseR: An R Interface to the JBrowse 2 Genome Browser},
  author={Hershberg, Elliot A and Stevens, Garrett and Diesh, Colin and Xie, Peter and De Jesus Martinez, Teresa and Buels, Robert and Stein, Lincoln and Holmes, Ian},
  journal={Bioinformatics}
}
```
