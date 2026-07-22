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

One hosted app, [**JBrowseR demos**](https://jbrowse.shinyapps.io/demos/), carries
every example below as a tab — shinyapps.io plans cap how many applications an
account may host, and a combined app spends one slot instead of one per demo.

The single-purpose apps are the ones to read: each is a page of code that does
one thing. Run any of them with `shiny::runApp("example_apps/<name>")`.

| App | What it shows |
|---|---|
| `basic_usage_with_text_index` | search a hub genome by gene name |
| `load_data_frame` | an R data frame as a track, with feature click-back |
| `interactive_peak_calling` | a slider that re-runs the analysis and repaints |
| `skbr3_gene_fusions` | SKBR3 long-read structural variants |
| `bookmarks_demo` | gene navigation, data-frame tracks, feature bookmarking |
| `load_config_json` | a full JBrowse `config.json` |
| `using_plugins` | a JBrowse 2 plugin loaded via a config |
| `demos` | all of the above as tabs — what gets hosted |

Hosting comes from `example_apps/deploy.R`, which the **shinyapps** workflow runs
on demand (Actions → shinyapps → Run workflow) and on each published release.

For browsers with no server at all, the website's
[live articles](https://gmod.github.io/JBrowseR/articles/live-browser.html)
embed the widget directly in the page.
