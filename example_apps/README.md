## Install deps

```R

install.packages(c('JBrowseR','crosstalk','DT'))
```

### Deploy

```R
deployApp('example_apps/basic_usage_with_text_index',account='gmod')
deployApp('example_apps/bookmarks_demo',account='gmod')
deployApp('example_apps/load_config_json',account='gmod')
deployApp('example_apps/load_data_frame',account='gmod')
deployApp('example_apps/skbr3_gene_fusions',account='gmod')

```

Regex to generate above list of commands

'<,'>s/^\(.\*\)/deployApp('example_apps\/\1',account='gmod')
