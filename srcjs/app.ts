import '@fontsource/roboto'
import '@jbrowse/react-app2/styles.css'

import {
  type CreateAppOptions,
  type JBrowseAppController,
  createApp,
  getSessionSnapshot,
  loadPlugins,
} from '@jbrowse/react-app2'
import { autorun, untracked } from 'mobx'

import { type Payload, type PluginSpec, defineWidget } from './widget'

async function runtimePlugins(specs?: PluginSpec[]) {
  const loaded = specs?.length ? await loadPlugins(specs) : []
  return loaded.map(p => p.plugin)
}

interface MaybeComparativeView {
  coarseVisibleLocStrings?: string
  views?: { coarseVisibleLocStrings?: string }[]
}

// A linear view reports its visible region as a coarseVisibleLocStrings string;
// a comparative view (synteny/dotplot) has no single string, so use the list of
// its sub-views' locstrings instead.
function viewLocation(view: MaybeComparativeView) {
  return typeof view.coarseVisibleLocStrings === 'string'
    ? view.coarseVisibleLocStrings
    : (view.views ?? []).map(v => v.coarseVisibleLocStrings).join(',')
}

interface MaybeSession {
  views: (MaybeComparativeView & {
    id?: string
    tracks?: { configuration: { trackId: string } }[]
  })[]
}

// The signal the session read-back rides on: which views exist, what each has
// open, and where each is looking. Deliberately NOT the whole snapshot —
// reading that would make the autorun depend on offsetPx, and a snapshot is
// kilobytes, so a drag would push one per pointer event to the Shiny server.
// coarseVisibleLocStrings is JBrowse's own debounced location, so this settles
// after a pan rather than firing during it.
function layoutSignal(session: MaybeSession) {
  return session.views
    .map(
      view =>
        `${view.id}:${viewLocation(view)}:${(view.tracks ?? [])
          .map(t => t.configuration.trackId)
          .join(',')}`,
    )
    .join('|')
}

// The layout the user built by hand goes to `<outputId>_session`, as the same
// plain JSON `session =` takes, so a Shiny app can offer "save this layout" and
// hand it straight back later.
//
// getSessionSnapshot, not a raw getSnapshot of the session: promoted
// display-type defaults live in whoever's browser produced them, so a raw
// snapshot replays differently for the next person to open it.
function reportSession(el: HTMLElement, controller: JBrowseAppController) {
  const { viewState } = controller
  return autorun(() => {
    const { session } = viewState
    if (!session) {
      return
    }
    // the only dependency this autorun should have; the snapshot read below is
    // untracked so it does not add offsetPx and everything else to the set
    layoutSignal(session)
    window.Shiny?.setInputValue(
      `${el.id}_session`,
      untracked(() => getSessionSnapshot(viewState)),
    )
  })
}

defineWidget<Payload<CreateAppOptions>, { destroy: () => void }>(
  'JBrowseRApp',
  async (el, x) => {
    const controller = createApp(el, {
      ...x,
      plugins: await runtimePlugins(x.plugins),
    })
    const dispose = reportSession(el, controller)
    return {
      destroy() {
        dispose()
        controller.destroy()
      },
    }
  },
)
