# Interactive peak calling

A control that **re-runs the analysis** rather than filtering a static file. A
binned coverage signal over hg38 chr17 carries a peak near BRCA1; the slider sets
the calling threshold, and every change reclassifies the bins in R, merges the
called ones into intervals, and re-renders the track. Click a called peak to read
its coordinates back via `input$selectedFeature`.

`call_peaks()` stands in for a real pipeline — swap it for MACS2 output, a DESeq2
contrast, or any R analysis whose result you want to see on the genome.

```r
shiny::runApp("example_apps/interactive_peak_calling")
```
