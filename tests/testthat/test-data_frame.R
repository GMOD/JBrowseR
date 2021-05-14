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
    name = c('foo', 'bar')
  )
  expect_error(
    track_data_frame(invalid_df, assembly),
    "data frame must contain columns: chrom, start, end, name."
  )
})

test_that("creating a data frame track returns the correct string", {
  assembly <- assembly(
    "https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz",
    bgzip = TRUE,
    aliases = c("GRCh37"),
    refname_aliases = "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/hg19_aliases.txt"
  )

  df <- data.frame(
    chrom = c(1, 2),
    start = c(123, 456),
    end = c(789, 101112),
    name = c('feature1', 'feature2')
  )

  remove_random_ids <- function(json_list) {
    for (i in seq_along(length(json_list$json_list$adapter$features))) {
      json_list$json_list$adapter$features[[i]]$uniqueId <- NULL
    }
  }

  # parse JSON, strip out the unique ID before comparing result
  df_json <- jsonlite::parse_json(track_data_frame(df, "my_features", assembly))
  df_json <- remove_random_ids(df_json)

  valid_json <- jsonlite::parse_json("{ \"type\": \"FeatureTrack\", \"name\": \"my_features\", \"assemblyNames\": [\"hg19\"], \"trackId\": \"hg19_my_features\", \"adapter\": { \"type\": \"FromConfigAdapter\", \"features\": [{\"refName\": \"1\", \"start\": 123, \"end\": 789, \"uniqueId\": \"29f30df147fdc145426288bfdda3dd9e\", \"name\": \"feature1\", \"type\": \"\", \"additional\": \"\" }, {\"refName\": \"2\", \"start\": 456, \"end\": 101112, \"uniqueId\": \"29f30df147fdc145426288bfdda3dd9e\", \"name\": \"feature2\", \"type\": \"\", \"additional\": \"\" }] } }")
  valid_json <- remove_random_ids(valid_json)

  expect_equal(df_json, valid_json)
})
