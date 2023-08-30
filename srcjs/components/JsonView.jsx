import {
  createViewState,
  JBrowseLinearGenomeView,
} from '@jbrowse/react-linear-genome-view'

import { messageShiny } from '../utils'

export default function View(props) {
  const configObject = JSON.parse(props.config)
  const {
    assembly,
    tracks,
    defaultSession,
    theme,
    text_index,
    plugins: pluginInput = [],
  } = configObject
  const location = props.location

  const [viewState, setViewState] = useState()
  useEffect(() => {
    // eslint-disable-next-line @typescript-eslint/no-floating-promises
    ;(async () => {
      try {
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
      } catch (e) {
        setError(e)
      }
    })()
  }, [])

  return <JBrowseLinearGenomeView viewState={viewState} />
}
