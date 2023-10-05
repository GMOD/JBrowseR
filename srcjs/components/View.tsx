import React from 'react'
import {
  createViewState,
  JBrowseLinearGenomeView,
} from '@jbrowse/react-linear-genome-view'

import { messageShiny } from '../utils'

export default function View(props: {
  tracks: string
  assembly: string
  location: string
  theme: string
  text_index: string
}) {
  const { theme, text_index, assembly, tracks, location, ...rest } =
    Object.fromEntries(
      Object.entries(props).map(([key, value]) => [
        key,
        key === 'location' ? value : JSON.parse(value),
      ]),
    )
  const state = createViewState({
    ...rest,
    onChange: messageShiny,
    configuration: { theme },
    aggregateTextSearchAdapters: text_index,
    location,
    assembly,
    tracks,
  })

  return <JBrowseLinearGenomeView viewState={state} />
}
