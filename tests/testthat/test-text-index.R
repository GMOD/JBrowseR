test_that("creating a text index returns valid configuration", {
  expect_equal(
    text_index(
      "https://jbrowse.org/genomes/GRCh38/trix/hg38.ix",
      "https://jbrowse.org/genomes/GRCh38/trix/hg38.ixx",
      "https://jbrowse.org/genomes/GRCh38/trix/meta.json",
      "hg38"
    ),
    "{\"type\": \"TrixTextSearchAdapter\", \"textSearchAdapterId\": \"hg38-index\", \"ixFilePath\": {\"uri\": \"https://jbrowse.org/genomes/GRCh38/trix/hg38.ix\", \"locationType\": \"UriLocation\"}, \"ixxFilePath\": {\"uri\": \"https://jbrowse.org/genomes/GRCh38/trix/hg38.ixx\", \"locationType\": \"UriLocation\"}, \"metaFilePath\": {\"uri\": \"https://jbrowse.org/genomes/GRCh38/trix/meta.json\", \"locationType\": \"UriLocation\"}, \"assemblyNames\": [\"hg38\"]}"
  )
})
