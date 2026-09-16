import '@fontsource/roboto'
import '@jbrowse/react-app2/styles.css'

import {
  type AssemblyInput,
  type CreateAppOptions,
  type JBrowseAppController,
  createApp,
  loadPlugins,
  resolveAssemblies,
} from '@jbrowse/react-app2'

import { type Payload, decodeLocalFiles, defineWidget } from './widget'

type AppPayload = Omit<Payload<CreateAppOptions>, 'assemblies'> & {
  assemblies?: AssemblyInput[]
}

defineWidget<AppPayload, JBrowseAppController>('JBrowseRApp', {
  build: async (el, x) =>
    createApp(el, {
      ...x,
      // a hub brings its own catalog and index, merged with the tracks and
      // search adapters in x
      ...(await resolveAssemblies(x.assemblies ?? [], x)),
      plugins: await loadPlugins(x.plugins ?? []),
      localFiles: decodeLocalFiles(x.localFiles),
      onSessionChange: session => {
        window.Shiny?.setInputValue(`${el.id}_session`, session)
      },
      onLocationChange: locations => {
        window.Shiny?.setInputValue(`${el.id}_location`, locations)
      },
      onFeatureSelect: feature => {
        window.Shiny?.setInputValue(`${el.id}_selected_feature`, feature)
      },
    }),
  live: (controller, changes) => {
    const keys = Object.keys(changes)
    if (!keys.every(key => key === 'session')) {
      return false
    }
    if (keys.length) {
      controller.setSession(changes.session).catch((e: unknown) => {
        console.error(e)
      })
    }
    return true
  },
})
