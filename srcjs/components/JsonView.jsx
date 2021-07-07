import {
  createViewState,
  JBrowseLinearGenomeView,
} from "@jbrowse/react-linear-genome-view";

import { messageShiny } from "../utils";

export default function View(props) {
  const configObject = JSON.parse(props.config);
  const { assembly, tracks, defaultSession, theme } = configObject;
  const location = props.location;
  const state = createViewState({
    assembly,
    tracks,
    defaultSession,
    location,
    onChange: messageShiny,
    configuration: { theme },
  });

  return (
    <JBrowseLinearGenomeView viewState={state} />
  );
}
