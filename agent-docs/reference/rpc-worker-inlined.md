# The RPC runs in an inlined worker, and that doubles the bundle

Both widgets pass `makeWorkerInstance` with the product's
`esm/rpcWorker?worker&inline`, as the anywidget does, so a deep BAM region no
longer blocks a Shiny page for the whole parse. `tools/verify_widget.mjs` checks
it positively, on the worker's own `self.rpcServer`. Inlining is the only road,
for reasons measured on 2026-08-27:

- **htmlwidgets delivers one file and nothing beside it.** The binding
  dependency comes back with `all_files: FALSE`, so a sibling worker chunk is
  never copied, and `saveWidget(selfcontained = TRUE)` inlines the bundle into
  an inline `<script>` with no script URL to resolve one against.
- **The portable spelling emits a root-absolute path.**
  `new Worker(new URL('.../rpcWorker', import.meta.url))` builds (with
  `worker.rollupOptions.output.inlineDynamicImports`) as
  `new Worker(new URL("/assets/rpcWorker-<hash>.js", ...))`, which resolves to
  `<origin>/assets/...` under Shiny, a loose `saveWidget` and a self-contained
  document alike.

The worker is built as `iife`: an `es` worker skips minification in lib mode
and inlines as unminified source, 12.7 MB against 10.0 MB for `JBrowseR.js`.
Measured on 2026-09-16, `JBrowseR.js` went from 5,007 kB to 9,997 kB (gzip
1,544 → 3,063 kB), `JBrowseRApp.js` from 5,884 kB to 11,674 kB (gzip 1,817 →
3,587 kB), and the package tarball from 5.16 MB to 8.44 MB against CRAN's 5 MB
guidance. The worker's copy of the adapters is a second copy; the lever is a
worker entry narrower than `corePlugins`.

`bundle.yaml` asserts the consequence rather than the reasoning: each bundle is
one file with nothing beside it, so a vite change that emits a chunk fails there
instead of 404ing in someone's knitted report.

If this is ever worth revisiting, the lever is a worker entry narrower than
`corePlugins` — the same one the anywidget's handoff names.
