import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// Two independent IIFE bundles, each an htmlwidget htmlwidgets loads as a plain
// <script>: the default `JBrowseR` (lean linear-genome-view) and, when
// JB_TARGET=app, `JBrowseRApp` (the full multi-view app for synteny/dotplot/etc).
// Each registers its binding via window.HTMLWidgets.widget(...) on load. They are
// built by separate `vite build` invocations (see the R build note) because
// inlineDynamicImports — which keeps each to one file, so there are no sibling
// chunks — forbids multiple entries in one build. RPC runs on the main thread
// (no makeWorkerInstance) in both.
const isApp = process.env.JB_TARGET === 'app'
const widgetName = isApp ? 'JBrowseRApp' : 'JBrowseR'

export default defineConfig({
  plugins: [react()],
  // No Node polyfills: the bundle has no Buffer at all, and every `process`
  // read but this one sits behind a `typeof process` guard. Only NODE_ENV needs
  // substituting — vite's lib mode leaves it alone, which would leave React and
  // MobX reading a `process` that isn't there. vite-plugin-node-polyfills used
  // to stand in for all of this, along with a shim for the `stream/web` its own
  // `stream` alias broke, and cost ~1.3MB of shims for one identifier. CI
  // asserts the bundle stays free of unpolyfilled globals.
  define: { 'process.env.NODE_ENV': '"production"' },
  resolve: {
    // The linked @jbrowse packages resolve react/mobx from the monorepo's
    // node_modules — a second copy. Dedupe the packages present in both trees
    // to one instance, or hooks/MobX break ("invalid hook call", multiple mobx
    // instances). This repo's versions must therefore track the monorepo's:
    // dedupe makes the version here win.
    dedupe: ['react', 'react-dom', 'react/jsx-runtime', 'mobx'],
  },
  build: {
    outDir: 'inst/htmlwidgets',
    emptyOutDir: false,
    lib: {
      entry: isApp ? 'srcjs/app.ts' : 'srcjs/index.ts',
      formats: ['iife'],
      name: widgetName,
      fileName: () => `${widgetName}.js`,
      cssFileName: widgetName,
    },
    rollupOptions: {
      output: {
        inlineDynamicImports: true,
      },
    },
  },
})
