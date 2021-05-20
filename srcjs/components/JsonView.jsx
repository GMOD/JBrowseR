import {
  createViewState,
  createJBrowseTheme,
  JBrowseLinearGenomeView,
  ThemeProvider,
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
  });

  const jbrowseTheme =
    theme !== undefined ? createJBrowseTheme(theme) : createJBrowseTheme();

  return (
    <ThemeProvider theme={jbrowseTheme}>
      <JBrowseLinearGenomeView viewState={state} />
    </ThemeProvider>
  );
}
