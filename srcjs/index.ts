import '@fontsource/roboto'

import {
  type CreateLinearGenomeViewOptions,
  type LinearGenomeViewController,
  createLinearGenomeView,
  loadPlugins,
} from '@jbrowse/react-linear-genome-view2'

type Plugins = { name: string; url: string }[]

// The whole-config shape (json_config): the JBrowse config-file layout, so its
// fields carry the createLinearGenomeView option names.
interface ConfigPayload {
  assembly: CreateLinearGenomeViewOptions['assembly']
  tracks?: CreateLinearGenomeViewOptions['tracks']
  defaultSession?: CreateLinearGenomeViewOptions['defaultSession']
  internetAccounts?: CreateLinearGenomeViewOptions['internetAccounts']
  aggregateTextSearchAdapters?: CreateLinearGenomeViewOptions['aggregateTextSearchAdapters']
  configuration?: CreateLinearGenomeViewOptions['configuration']
  plugins?: Plugins
  theme?: unknown
}

// The widget payload (x) htmlwidgets hands renderValue is one of two shapes,
// discriminated by `config`: a whole `config` from json_config (a string when
// read raw from a file, an object once htmlwidgets serializes an R list), or the
// individual fields the R helpers emit (where `assembly` is always present).
interface IndividualPayload {
  config?: undefined
  assembly: CreateLinearGenomeViewOptions['assembly']
  tracks?: CreateLinearGenomeViewOptions['tracks']
  defaultSession?: CreateLinearGenomeViewOptions['defaultSession']
  location?: string
  plugins?: Plugins
  textSearch?:
    | NonNullable<
        CreateLinearGenomeViewOptions['aggregateTextSearchAdapters']
      >[number]
    | CreateLinearGenomeViewOptions['aggregateTextSearchAdapters']
  theme?: unknown
}

type WidgetPayload =
  | IndividualPayload
  | { config: string | ConfigPayload; location?: string }

function parseMaybe(value: string | ConfigPayload) {
  return typeof value === 'string'
    ? (JSON.parse(value) as ConfigPayload)
    : value
}

function asArray(
  value: IndividualPayload['textSearch'],
): CreateLinearGenomeViewOptions['aggregateTextSearchAdapters'] {
  return value === undefined ? undefined : ([] as unknown[]).concat(value)
}

// Turn the widget payload into options for createLinearGenomeView. The R side
// sends either individual fields (assembly/tracks/...) or a whole `config`
// (from json_config); the latter is the JBrowse config-file shape.
async function optionsForPayload(
  x: WidgetPayload,
): Promise<CreateLinearGenomeViewOptions> {
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
function onFeatureSelect(feature: unknown) {
  window.Shiny?.setInputValue('selectedFeature', feature)
}

window.HTMLWidgets?.widget<WidgetPayload>({
  name: 'JBrowseR',
  type: 'output',
  factory(el) {
    let controller: LinearGenomeViewController | undefined
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
          .catch((e: unknown) => {
            console.error(e)
          })
      },
      resize() {},
    }
  },
})
