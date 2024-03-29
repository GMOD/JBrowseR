% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/text-index.R
\name{text_index}
\alias{text_index}
\title{Create configuration for a JBrowse 2 text index}
\usage{
text_index(ix_uri, ixx_uri, meta_uri, assembly)
}
\arguments{
\item{ix_uri}{the URI for the ix file}

\item{ixx_uri}{the URI for the ixx file}

\item{meta_uri}{the URI for the JSON metadata file}

\item{assembly}{the assembly associated with the text index}
}
\value{
a character vector with the JSON text index adapter.
}
\description{
Creates the necessary configuration string for an adapter to a text index for
gene name search in the browser.
}
\details{
Note: this function currently only supports aggregate indices.

For more information on JBrowse 2 text indices, visit:
\url{https://jbrowse.org/jb2/docs/config_guide/#text-searching}
}
\examples{
text_index(
"https://jbrowse.org/genomes/hg19/trix/hg19.ix",
"https://jbrowse.org/genomes/hg19/trix/hg19.ixx",
"https://jbrowse.org/genomes/hg19/trix/meta.json",
"hg19"
)
}
