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

See [`../example_apps`](../example_apps) for Shiny applications:

- `basic_usage_with_text_index` — search a hub genome by gene name
- `load_data_frame` — render an R data frame as a track, with feature click-back
- `load_config_json` — load a full JBrowse `config.json`
- `using_plugins` — load a JBrowse 2 plugin via a config
- `skbr3_gene_fusions` — SKBR3 cancer cell line long-read structural variants
- `bookmarks_demo` — an interactive tour: gene navigation, data-frame tracks,
  and feature bookmarking
