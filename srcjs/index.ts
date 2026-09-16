import '@fontsource/roboto'

import {
  type CreateLinearGenomeViewOptions,
  type LinearGenomeViewController,
  type LinearGenomeViewState,
  createLinearGenomeView,
  loadPlugins,
} from '@jbrowse/react-linear-genome-view2'

import { type Payload, decodeLocalFiles, defineWidget } from './widget'

type Options = Payload<CreateLinearGenomeViewOptions>

const LIVE_OPTIONS = new Set(['tracks', 'location', 'localFiles'])

function report(el: HTMLElement, suffix: string) {
  return (value: unknown) => {
    window.Shiny?.setInputValue(`${el.id}_${suffix}`, value)
  }
}

// a registered name keeps the blob its open tracks read, so changed or dropped
// bytes behind one need a rebuild
function onlyAddsFiles(previous: Options, changes: Partial<Options>) {
  return (
    !('localFiles' in changes) ||
    Object.entries(previous.localFiles ?? {}).every(
      ([name, base64]) => changes.localFiles?.[name] === base64,
    )
  )
}

defineWidget<Options, LinearGenomeViewController>('JBrowseR', {
  build: async (el, x, fail) =>
    createLinearGenomeView(el, {
      ...x,
      plugins: await loadPlugins(x.plugins ?? []),
      localFiles: decodeLocalFiles(x.localFiles),
      onFeatureSelect: report(el, 'selected_feature'),
      onLocationChange: report(el, 'location'),
      onSessionChange: report(el, 'session'),
      onError: fail,
    }),
  live: (controller, changes, previous) => {
    const keys = Object.keys(changes)
    if (
      !keys.every(key => LIVE_OPTIONS.has(key)) ||
      !onlyAddsFiles(previous, changes)
    ) {
      return false
    }
    if (keys.length) {
      const state: LinearGenomeViewState = {}
      if ('tracks' in changes) {
        state.tracks = changes.tracks ?? []
      }
      if ('location' in changes) {
        state.location = changes.location
      }
      if ('localFiles' in changes) {
        state.localFiles = decodeLocalFiles(changes.localFiles)
      }
      controller.update(state).catch((e: unknown) => {
        console.error(e)
      })
    }
    return true
  },
})
