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
// browsers on one page don't overwrite each other.
//
// A bare global `selectedFeature` was set alongside it until 0.12.0. It could
// not be made correct: two browsers on a page overwrite each other's, and
// inside a Shiny module the module cannot read it at all.
function featureSelectHandler(el: HTMLElement) {
  return (feature: unknown) => {
    window.Shiny?.setInputValue(`${el.id}_selected_feature`, feature)
  }
}

// The visible region goes to `<outputId>_location`, so a server can recompute
// for what the user is actually looking at.
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
  // What `update_location()` reaches, and the whole of it. What is left on the
  // controller is addTrack/removeTrack/addLocalFiles; a Shiny app expresses
  // those by re-rendering the widget, which is what renderJBrowseR already does
  // with the track list. Moving the locus is the one interaction that repeats
  // often enough for a rebuild to be visibly wrong.
  (controller, call) => {
    if (call.method === 'setLocation') {
      const location = call.args?.location
      if (typeof location === 'string') {
        // async: the view resolves the string (a gene name goes through the
        // search index) and may fail. Report it where the other build failures
        // go rather than as an unhandled rejection.
        controller.setLocation(location).catch((e: unknown) => {
          console.error(e)
        })
      }
    } else {
      console.warn(`JBrowseR: unknown proxy call "${call.method}"`)
    }
  },
)
