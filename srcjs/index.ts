import '@fontsource/roboto'

import {
  type CreateLinearGenomeViewOptions,
  type LinearGenomeViewController,
  type LinearGenomeViewState,
  createLinearGenomeView,
  loadPlugins,
} from '@jbrowse/react-linear-genome-view2'

import {
  type Payload,
  decodeLocalFiles,
  defineWidget,
  sameJson,
} from './widget'

type Options = Payload<CreateLinearGenomeViewOptions>

// The clicked feature goes to `<outputId>_selected_feature` — el.id is the
// output element's id, already namespaced by Shiny inside a module, so two
// browsers on one page don't overwrite each other.
//
// A bare global `selectedFeature` was set alongside it until 0.12.0. It could
// not be made correct: two browsers on a page overwrite each other's, and
// inside a Shiny module the module cannot read it at all.
function report(el: HTMLElement, suffix: string) {
  return (value: unknown) => {
    window.Shiny?.setInputValue(`${el.id}_${suffix}`, value)
  }
}

// What the controller reconciles into a live view. Everything else the payload
// carries — the assembly, a session, plugins, the configuration block — is what
// the engine is BUILT from, so stating a new one is a different browser.
//
// The comparison below runs on everything *outside* these three, so a field the
// payload gains lands on the rebuild side by default. That is the safe
// direction: the cost of a wrong answer there is the rebuild this used to do
// unconditionally, where a field wrongly treated as live would be dropped.
function buildInputs({ tracks, location, localFiles, ...rest }: Options) {
  return rest
}

// `localFiles` only ever grows in a live view: a name already registered keeps
// the blob its open tracks point at, because swapping it underneath would leave
// them reading bytes nothing else references. So a payload that changes or
// drops the bytes behind a name it already sent is one only a rebuild can
// express — a fresh controller registers the new bytes under a fresh blob.
function onlyAddsFiles(previous: Options, next: Options) {
  return Object.entries(previous.localFiles ?? {}).every(
    ([name, base64]) => next.localFiles?.[name] === base64,
  )
}

function absorb(
  controller: LinearGenomeViewController,
  previous: Options,
  next: Options,
) {
  if (
    !sameJson(buildInputs(previous), buildInputs(next)) ||
    !onlyAddsFiles(previous, next)
  ) {
    return false
  }
  const state: LinearGenomeViewState = {}
  if (!sameJson(previous.tracks, next.tracks)) {
    // `?? []` rather than leaving it out: a payload that stopped stating tracks
    // wants none open, and `update` reads an omitted field as "leave alone"
    state.tracks = next.tracks ?? []
  }
  if (!sameJson(previous.location, next.location)) {
    state.location = next.location
  }
  if (!sameJson(previous.localFiles, next.localFiles)) {
    state.localFiles = decodeLocalFiles(next.localFiles)
  }
  update(controller, state)
  return true
}

// The view resolves what it is handed — a gene name goes through the search
// index, a track config through the adapter guess — and may fail. Report it
// where the build failures go rather than as an unhandled rejection. `update`
// also rejects when the build it awaits failed, which `onError` has already
// reported.
function update(
  controller: LinearGenomeViewController,
  state: LinearGenomeViewState,
) {
  controller.update(state).catch((e: unknown) => {
    console.error(e)
  })
}

defineWidget<Options, LinearGenomeViewController>(
  'JBrowseR',
  async (el, x, fail) =>
    createLinearGenomeView(el, {
      ...x,
      // the loadPlugins records go through whole rather than mapped to
      // `.plugin`: the definition is what lets the RPC worker load the same
      // plugin, so a stripped record leaves it missing there
      plugins: await loadPlugins(x.plugins ?? []),
      localFiles: decodeLocalFiles(x.localFiles),
      onFeatureSelect: report(el, 'selected_feature'),
      // The view fires this with `coarseVisibleLocStrings`, which settles after
      // a pan/zoom rather than tracking every frame — a raw read would put a
      // Shiny round-trip behind every pointer event of a drag.
      onLocationChange: report(el, 'location'),
      // The layout the user built by hand goes to `<outputId>_session`, in the
      // same plain JSON `session =` takes, so a Shiny app can offer "save this
      // view" and hand it straight back later. Same name and shape as
      // JBrowseRApp()'s, so an app that grows from one view to several keeps
      // its server.
      onSessionChange: report(el, 'session'),
      onError: fail,
    }),
  {
    absorb,
    // `update_location()` is the whole of what a Shiny server can drive live,
    // and it states a location the same way a re-render does. Only `location`
    // is read out because it is the only field R sends; another one is a line
    // here and a line there.
    dispatch: (controller, call) => {
      const location = call.args?.location
      if (call.method === 'update' && typeof location === 'string') {
        update(controller, { location })
      } else {
        console.warn(`JBrowseR: unknown proxy call "${call.method}"`)
      }
    },
  },
)
