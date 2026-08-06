import '@fontsource/roboto'
import '@jbrowse/react-app2/styles.css'

import {
  type CreateAppOptions,
  createApp,
  loadPlugins,
} from '@jbrowse/react-app2'

import { type Payload, defineWidget } from './widget'

defineWidget<Payload<CreateAppOptions>, { destroy: () => void }>(
  'JBrowseRApp',
  async (el, x) =>
    createApp(el, {
      ...x,
      // the loadPlugins records go through whole rather than mapped to
      // `.plugin`: the definition is what lets the RPC worker load the same
      // plugin, so a stripped record leaves it missing there
      plugins: await loadPlugins(x.plugins ?? []),
      // The layout the user built by hand goes to `<outputId>_session`, as the
      // same plain JSON `session =` takes, so a Shiny app can offer "save this
      // layout" and hand it straight back later. createApp settles it on a
      // coarse signal, so it lands after a gesture rather than during one.
      //
      // createApp also offers onLocationChange, which would give the app a
      // `<outputId>_location` the way JBrowseR() has one. Left off until the
      // roxygen for JBrowseRApp-shiny describes it.
      onSessionChange: session => {
        window.Shiny?.setInputValue(`${el.id}_session`, session)
      },
    }),
)
