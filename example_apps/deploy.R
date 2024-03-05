#!/usr/bin/env Rscript

library(rsconnect)
deployApp("example_apps/basic_usage_with_text_index", account = "gmod")
deployApp("example_apps/bookmarks_demo", account = "gmod")
deployApp("example_apps/load_config_json", account = "gmod")
deployApp("example_apps/load_data_frame", account = "gmod")
deployApp("example_apps/skbr3_gene_fusions", account = "gmod")
deployApp("example_apps/using_plugins", account = "gmod")


## install.packages(c('JBrowseR','crosstalk','DT','rsconnect'))
##' <,'>s/^\(.\*\)/deployApp('example_apps\/\1',account='gmod')
