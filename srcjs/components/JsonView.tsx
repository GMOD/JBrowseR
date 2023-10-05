import React from 'react'
import {
  createViewState,
  JBrowseLinearGenomeView,
  loadPlugins,
} from '@jbrowse/react-linear-genome-view'
import { ErrorMessage } from '@jbrowse/core/ui'

import { messageShiny } from '../utils'

type ViewState = ReturnType<typeof createViewState>
export default function View({
  config,
  location,
}: {
  location: string
  config: string
}) {
  const [viewState, setViewState] = React.useState<ViewState>()
  const [error, setError] = React.useState<unknown>()
  React.useEffect(() => {
    // eslint-disable-next-line @typescript-eslint/no-floating-promises
    ;(async () => {
      try {
        const {
          assembly,
          tracks,
          defaultSession,
          theme,
          text_index,
          plugins: pluginInput = [],
        } = JSON.parse(config)
        const plugins = await loadPlugins(pluginInput)
        const state = createViewState({
          assembly,
          tracks,
          defaultSession,
          location,
          onChange: messageShiny,
          configuration: { theme },
          aggregateTextSearchAdapters: [text_index],
          plugins: plugins.map(p => p.plugin),
        })
        setViewState(state)
      } catch (error) {
        console.error(error)
        setError(error)
      }
    })()
  }, [config, location])

  return error ? (
    <ErrorMessage error={error} />
  ) : viewState ? (
    <JBrowseLinearGenomeView viewState={viewState} />
  ) : (
    <h3>Loading...</h3>
  )
}
