<!-- README.md is generated from README.Rmd. Please edit that file -->

# JBrowseR <img src='man/figures/logo.png' align="right" height="136" />

<!-- badges: start -->

[![R-CMD-check](https://github.com/GMOD/JBrowseR/workflows/R-CMD-check/badge.svg)](https://github.com/gmod/JBrowseR/actions)
[![CRAN
status](https://www.r-pkg.org/badges/version/JBrowseR)](https://CRAN.R-project.org/package=JBrowseR)

<!-- badges: end -->

JBrowseR is an R package that provides a simple and clean interface to
[JBrowse 2](https://jbrowse.org/jb2/) for R users. Using JBrowseR, you can:

- Embed the JBrowse 2 genome browser in **R Markdown** documents and **Shiny
  applications**
- Deploy a genome browser directly from the R console to view your data
- Customize your genome browser to display your own data

With this functionality, you can deploy a first-class genome browser with your
data in just a few lines of R code!

## Installation

You can install the released version of JBrowseR from
[CRAN](https://CRAN.R-project.org) with:

```r
install.packages("JBrowseR")
```

And the development version from [GitHub](https://github.com/) with:

```r
# install.packages("devtools")
devtools::install_github("gmod/JBrowseR")
```

## Example

This line of code can be used to launch a genome browser from your R console:

```r
library(JBrowseR)
JBrowseR("ViewHg19",
         location = "10:29,838,737..29,838,819")
```

<img src="man/figures/README-example-1.png" width="100%" />

## Getting started

In order to get started with JBrowseR, please refer to the vignette that best
suits your needs:

- [Introduction](https://gmod.github.io/JBrowseR/articles/JBrowseR.html)
- [Custom browser tutorial](https://gmod.github.io/JBrowseR/articles/custom-browser-tutorial.html)
- [JSON configuration tutorial](https://gmod.github.io/JBrowseR/articles/json-tutorial.html)
- [Creating URLs](https://gmod.github.io/JBrowseR/articles/creating-urls.html)

## Citation

If you use JBrowseR in your research, please cite the following publication:

[Hershberg et al., 2021. JBrowseR: An R Interface to the JBrowse 2 Genome Browser](https://doi.org/10.1093/bioinformatics/btab459)

    @article{hershberg2021jbrowser,
      title={JBrowseR: An R Interface to the JBrowse 2 Genome Browser},
      author={Hershberg, Elliot A and Stevens, Garrett and Diesh, Colin and Xie, Peter and De Jesus Martinez, Teresa and Buels, Robert and Stein, Lincoln and Holmes, Ian},
      journal={Bioinformatics}
    }
