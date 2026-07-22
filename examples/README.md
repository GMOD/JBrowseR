# JBrowseR examples

## Google Colab (R runtime)

Runnable notebooks that install JBrowseR and render live browsers. Open one,
then set **Runtime → Change runtime type → R** and run all cells.

- **Getting started** — a one-line human genome, alignments, a track built from
  an R data frame, and cancer structural variants
  [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/GMOD/JBrowseR/blob/main/examples/JBrowseR_colab.ipynb)
- **Comparing genomes** — four *E. coli* strains in a linear synteny view and a
  dotplot, from one all-vs-all PAF
  [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/GMOD/JBrowseR/blob/main/examples/JBrowseR_comparative_colab.ipynb)

## Shiny apps

Run any of these locally with `shiny::runApp("example_apps/<name>")`, or open the
hosted copy. Hosting comes from `example_apps/deploy.R`, which the **shinyapps**
workflow runs on demand (Actions → shinyapps → Run workflow) and on each
published release; the URLs below follow whichever account is in the repo's
`SHINYAPPS_NAME` secret.

| App | What it shows | Hosted |
|---|---|---|
| `basic_usage_with_text_index` | search a hub genome by gene name | [live](https://jbrowse.shinyapps.io/basic_usage_with_text_index/) |
| `load_data_frame` | an R data frame as a track, with feature click-back | [live](https://jbrowse.shinyapps.io/load_data_frame/) |
| `load_config_json` | a full JBrowse `config.json` | [live](https://jbrowse.shinyapps.io/load_config_json/) |
| `skbr3_gene_fusions` | SKBR3 long-read structural variants | [live](https://jbrowse.shinyapps.io/skbr3_gene_fusions/) |
| `bookmarks_demo` | gene navigation, data-frame tracks, feature bookmarking | [live](https://jbrowse.shinyapps.io/bookmarks_demo/) |
| `interactive_peak_calling` | a slider that re-runs the analysis and repaints | not deployed yet |
| `using_plugins` | a JBrowse 2 plugin loaded via a config | not deployed yet |

For browsers with no server at all, the website's
[live articles](https://gmod.github.io/JBrowseR/articles/live-browser.html)
embed the widget directly in the page.
