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

// The clicked feature goes to `<outputId>_selected_feature` — el.id is the
// output element's id, already namespaced by Shiny inside a module, so two
// browsers on one page don't overwrite each other. The bare `selectedFeature`
// every existing app observes is still set, and still global.
function featureSelectHandler(el: HTMLElement) {
  return (feature: unknown) => {
    window.Shiny?.setInputValue(`${el.id}_selected_feature`, feature)
    window.Shiny?.setInputValue('selectedFeature', feature)
  }
}

defineWidget<Payload<CreateLinearGenomeViewOptions>, LinearGenomeViewController>(
  'JBrowseR',
  async (el, x) =>
    createLinearGenomeView(el, {
      ...x,
      plugins: await runtimePlugins(x.plugins),
      onFeatureSelect: featureSelectHandler(el),
    }),
)
