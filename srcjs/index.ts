import '@fontsource/roboto'

import {
  type CreateLinearGenomeViewOptions,
  type LinearGenomeViewController,
  createLinearGenomeView,
  loadPlugins,
} from '@jbrowse/react-linear-genome-view2'

import { type Payload, type PluginSpec, defineWidget } from './widget'

async function runtimePlugins(specs?: PluginSpec[]) {
  const loaded = specs?.length ? await loadPlugins(specs) : []
  return loaded.map(p => p.plugin)
}

// Report the clicked feature back to Shiny under the same input id the old
// widget used, so existing Shiny apps keep working.
function onFeatureSelect(feature: unknown) {
  window.Shiny?.setInputValue('selectedFeature', feature)
}

defineWidget<Payload<CreateLinearGenomeViewOptions>, LinearGenomeViewController>(
  'JBrowseR',
  async (el, x) =>
    createLinearGenomeView(el, {
      ...x,
      plugins: await runtimePlugins(x.plugins),
      onFeatureSelect,
    }),
)
