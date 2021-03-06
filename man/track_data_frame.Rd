% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data_frame.R
\name{track_data_frame}
\alias{track_data_frame}
\title{Create a track from an R data frame for a custom JBrowse 2 view}
\usage{
track_data_frame(track_data, track_name, assembly)
}
\arguments{
\item{track_data}{the data frame with track data. Must have cols:
\code{chrom}, \code{start}, \code{end}, \code{name}. The column
\code{additional} can optionally be include with more feature information.
If a \code{score} column is present, it will be used and the track will
be rendered to display quantitative features.}

\item{track_name}{the name to use for the track}

\item{assembly}{the config string generated by \code{assembly}}
}
\value{
a character vector of stringified track JSON configuration
}
\description{
Creates the necessary configuration string for an R data frame so that it can
be viewed as a track in a JBrowse custom linear genome view.
}
\examples{
assembly <- assembly("https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz", bgzip = TRUE)

df <- data.frame(
        chrom = c(1, 2),
        start = c(123, 456),
        end = c(789, 101112),
        name = c('feature1', 'feature2')
      )

track_data_frame(df, "my_features", assembly)
}
