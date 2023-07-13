## Install deps

```R

install.packages(c('JBrowseR','crosstalk','DT'))
```

### Deploy

```R

deployApp('example_apps/basic_usage',account='gmod')
deployApp('example_apps/bookmarks',account='gmod')
deployApp('example_apps/custom_theme',account='gmod')
deployApp('example_apps/hg38_demo',account='gmod')
deployApp('example_apps/load_data_frame',account='gmod')
deployApp('example_apps/load_json',account='gmod')
deployApp('example_apps/multi',account='gmod')
deployApp('example_apps/skbr3_gene_fusions',account='gmod')

```
