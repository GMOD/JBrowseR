import { createRequire } from 'node:module'
import { dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'
import { nodePolyfills } from 'vite-plugin-node-polyfills'

const require = createRequire(import.meta.url)

const streamWebShim = fileURLToPath(
  new URL('./srcjs/stream-web-shim.js', import.meta.url),
)

// vite-plugin-node-polyfills injects `import 'vite-plugin-node-polyfills/shims/<x>'`
// into any module that references process/global/Buffer. Modules pulled in
// through the linked (monorepo) @jbrowse packages live outside this repo's
// node_modules, so that bare specifier can't resolve from their location. Pin
// the three shims to this repo's copy by resolving them here.
const shimAliases = ['process', 'global', 'buffer'].map(name => ({
  find: `vite-plugin-node-polyfills/shims/${name}`,
  replacement: dirname(
    dirname(require.resolve(`vite-plugin-node-polyfills/shims/${name}`)),
  ),
}))

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
  plugins: [
    // nodePolyfills adds a `stream` prefix-alias that rewrites `stream/web` to
    // the nonexistent `stream-browserify/web`. Catch `stream/web` wherever it
    // lands and point at the browser's native WHATWG streams.
    {
      name: 'stream-web-shim',
      enforce: 'pre',
      resolveId(id) {
        const web =
          id === 'stream/web' ||
          id === 'node:stream/web' ||
          id.endsWith('stream-browserify/web')
        return web ? streamWebShim : null
      },
    },
    react(),
    nodePolyfills({ exclude: ['stream/web'] }),
  ],
  resolve: {
    // The linked @jbrowse packages resolve react/mobx from the monorepo's
    // node_modules — a second copy. Dedupe the packages present in both trees
    // to one instance, or hooks/MobX break ("invalid hook call", multiple mobx
    // instances).
    dedupe: ['react', 'react-dom', 'react/jsx-runtime', 'mobx'],
    alias: shimAliases,
  },
  build: {
    outDir: 'inst/htmlwidgets',
    emptyOutDir: false,
    lib: {
      entry: isApp ? 'srcjs/app.jsx' : 'srcjs/index.jsx',
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
