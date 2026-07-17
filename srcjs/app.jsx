import '@fontsource/roboto'
import '@jbrowse/react-app2/styles.css'

import { createApp, loadPlugins } from '@jbrowse/react-app2'

// The R helpers emit plain lists (htmlwidgets serializes them to JSON), but
// config = json_config() passes a raw JSON string, so parse when a string
// arrives.
function parseMaybe(value) {
  return typeof value === 'string' ? JSON.parse(value) : value
}

// Turn the widget payload (x) into createApp options. The R side sends either
// individual fields (assemblies/tracks/views) or a whole `config` (from
// json_config), which is the JBrowse config-file shape.
async function optionsForPayload(x) {
  const cfg = x.config !== undefined ? parseMaybe(x.config) : x
  const loaded = cfg.plugins ? await loadPlugins(cfg.plugins) : []
  return {
    assemblies: cfg.assemblies,
    tracks: cfg.tracks,
    views: cfg.views,
    plugins: loaded.map(p => p.plugin),
    configuration:
      cfg.configuration ?? (cfg.theme ? { theme: cfg.theme } : undefined),
  }
}

if (window.HTMLWidgets) {
  window.HTMLWidgets.widget({
    name: 'JBrowseRApp',
    type: 'output',
    factory(el) {
      let controller
      // renderValue can fire more than once in Shiny; a token drops stale async
      // builds so the last payload wins
      let seq = 0
      return {
        renderValue(x) {
          const token = ++seq
          if (controller) {
            controller.destroy()
            controller = undefined
          }
          optionsForPayload(x)
            .then(opts => {
              if (token === seq) {
                controller = createApp(el, opts)
              }
            })
            .catch(e => {
              console.error(e)
            })
        },
        resize() {},
      }
    },
  })
}
