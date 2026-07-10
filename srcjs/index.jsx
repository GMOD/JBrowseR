import '@fontsource/roboto'

import { createLinearGenomeView } from '@jbrowse/embedded-linear-genome-view'
import { loadPlugins } from '@jbrowse/react-linear-genome-view2'

// The R helpers emit plain objects/arrays (htmlwidgets serializes R lists to
// JSON), but json_config() passes a raw JSON string read from a file, so parse
// when a string arrives.
function parseMaybe(value) {
  return typeof value === 'string' ? JSON.parse(value) : value
}

function asArray(value) {
  return value === undefined ? undefined : [].concat(value)
}

// Turn the widget payload (x) into options for createLinearGenomeView. The R
// side sends either individual fields (assembly/tracks/...) or a whole `config`
// (from json_config); the latter is the JBrowse config-file shape.
async function optionsForPayload(x) {
  if (x.config !== undefined) {
    const cfg = parseMaybe(x.config)
    const loaded = await loadPlugins(cfg.plugins ?? [])
    return {
      assembly: cfg.assembly,
      tracks: cfg.tracks,
      defaultSession: cfg.defaultSession,
      location: x.location,
      internetAccounts: cfg.internetAccounts,
      plugins: loaded.map(p => p.plugin),
      aggregateTextSearchAdapters: cfg.aggregateTextSearchAdapters,
      configuration:
        cfg.configuration ?? (cfg.theme ? { theme: cfg.theme } : undefined),
    }
  }
  const loaded = x.plugins ? await loadPlugins(x.plugins) : []
  return {
    // a bare string is a hub name ("hg38"); an object is a full assembly config
    assembly: x.assembly,
    tracks: x.tracks,
    defaultSession: x.defaultSession,
    location: x.location,
    plugins: loaded.map(p => p.plugin),
    aggregateTextSearchAdapters: asArray(x.textSearch),
    configuration: x.theme ? { theme: x.theme } : undefined,
  }
}

// Report the clicked feature back to Shiny under the same input id the old
// widget used, so existing Shiny apps keep working.
function onFeatureSelect(feature) {
  if (window.Shiny) {
    window.Shiny.setInputValue('selectedFeature', feature)
  }
}

if (window.HTMLWidgets) {
  window.HTMLWidgets.widget({
    name: 'JBrowseR',
    type: 'output',
    factory(el) {
      let controller
      // renderValue can fire more than once in Shiny; a token drops stale
      // async builds so the last payload wins
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
                controller = createLinearGenomeView(el, {
                  ...opts,
                  onFeatureSelect,
                })
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
