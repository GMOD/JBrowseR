test_that("data frame validation works", {
  assembly <- assembly(
    "https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz",
    bgzip = TRUE,
    aliases = c("GRCh37"),
    refname_aliases = "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/hg19_aliases.txt"
  )

  list_input <- list(
    c("chrom1", "chrom2"),
    c('123', '456'),
    c('789', '101112'),
    c('foo', 'bar')
  )
  expect_error(
    track_data_frame(list_input, assembly),
    "track data must be a data frame."
  )

  invalid_df <- data.frame(
    chroms = c("chrom1", "chrom2"),
    start = c('123', '456'),
    end = c('789', '101112'),
    id = c('foo', 'bar')
  )
  expect_error(
    track_data_frame(invalid_df, assembly),
    "data frame must contain columns: chrom, start, end, id."
  )
})
