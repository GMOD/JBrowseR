import '@fontsource/roboto'

import {
  type CreateLinearGenomeViewOptions,
  type LinearGenomeViewController,
  createLinearGenomeView,
  loadPlugins,
} from '@jbrowse/react-linear-genome-view2'

import { type Payload, defineWidget } from './widget'

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

// The visible region goes to `<outputId>_location`, so a server can recompute
// for what the user is actually looking at. No global twin: `selectedFeature`
// has one only for apps written before the namespacing, and a second browser on
// the page would fight over it.
//
// The view fires this with `coarseVisibleLocStrings`, which settles after a
// pan/zoom rather than tracking every frame — a raw read would put a Shiny
// round-trip behind every pointer event of a drag.
function locationChangeHandler(el: HTMLElement) {
  return (location: string) => {
    window.Shiny?.setInputValue(`${el.id}_location`, location)
  }
}

defineWidget<Payload<CreateLinearGenomeViewOptions>, LinearGenomeViewController>(
  'JBrowseR',
  async (el, x) =>
    createLinearGenomeView(el, {
      ...x,
      // the loadPlugins records go through whole rather than mapped to
      // `.plugin`: the definition is what lets the RPC worker load the same
      // plugin, so a stripped record leaves it missing there
      plugins: await loadPlugins(x.plugins ?? []),
      onFeatureSelect: featureSelectHandler(el),
      onLocationChange: locationChangeHandler(el),
    }),
)
