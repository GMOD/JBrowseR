import '@fontsource/roboto'
import '@jbrowse/react-app2/styles.css'

import {
  type CreateAppOptions,
  type JBrowseAppController,
  createApp,
  loadPlugins,
} from '@jbrowse/react-app2'

import { type Payload, type PluginSpec, defineWidget } from './widget'

async function runtimePlugins(specs?: PluginSpec[]) {
  const loaded = specs?.length ? await loadPlugins(specs) : []
  return loaded.map(p => p.plugin)
}

defineWidget<Payload<CreateAppOptions>, JBrowseAppController>(
  'JBrowseRApp',
  async (el, x) =>
    createApp(el, { ...x, plugins: await runtimePlugins(x.plugins) }),
)
