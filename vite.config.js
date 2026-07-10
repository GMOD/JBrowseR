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

// Bundle everything into a single IIFE that htmlwidgets loads as a plain
// <script>. On load it calls window.HTMLWidgets.widget(...) to register the
// binding. inlineDynamicImports keeps it to one file so there are no sibling
// chunks (htmlwidgets only serves inst/htmlwidgets/JBrowseR.js). RPC runs on
// the main thread (no makeWorkerInstance), matching the anywidget bundle.
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
      entry: 'srcjs/index.jsx',
      formats: ['iife'],
      name: 'JBrowseR',
      fileName: () => 'JBrowseR.js',
      cssFileName: 'JBrowseR',
    },
    rollupOptions: {
      output: {
        inlineDynamicImports: true,
      },
    },
  },
})
