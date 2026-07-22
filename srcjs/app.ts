import '@fontsource/roboto'
import '@jbrowse/react-app2/styles.css'

import {
  type CreateAppOptions,
  type JBrowseAppController,
  createApp,
  loadPlugins,
} from '@jbrowse/react-app2'

type Plugins = { name: string; url: string }[]

// The multi-view app config: assemblies + tracks are config lists, views is the
// [{type, init}] list reaching synteny/dotplot/circular/etc.
interface AppConfig {
  assemblies: CreateAppOptions['assemblies']
  tracks: CreateAppOptions['tracks']
  views?: CreateAppOptions['views']
  configuration?: CreateAppOptions['configuration']
  plugins?: Plugins
  theme?: unknown
}

// The widget payload (x) htmlwidgets hands renderValue is one of two shapes,
// discriminated by `config`: either the individual fields the R helpers emit, or
// a whole `config` from json_config (a raw JSON string).
type WidgetPayload =
  | (AppConfig & { config?: undefined })
  | { config: string | AppConfig }

// config = json_config() passes a raw JSON string; the R helpers otherwise emit
// plain lists htmlwidgets has already serialized. Parse only when a string.
function parseMaybe(value: string | AppConfig) {
  return typeof value === 'string' ? (JSON.parse(value) as AppConfig) : value
}

// Turn the widget payload (x) into createApp options. The R side sends either
// individual fields (assemblies/tracks/views) or a whole `config` (from
// json_config), which is the JBrowse config-file shape.
async function optionsForPayload(
  x: WidgetPayload,
): Promise<CreateAppOptions> {
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

window.HTMLWidgets?.widget<WidgetPayload>({
  name: 'JBrowseRApp',
  type: 'output',
  factory(el) {
    let controller: JBrowseAppController | undefined
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
          .catch((e: unknown) => {
            console.error(e)
          })
      },
      resize() {},
    }
  },
})
