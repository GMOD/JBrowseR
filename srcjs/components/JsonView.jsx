import {
  createViewState,
  createJBrowseTheme,
  JBrowseLinearGenomeView,
  ThemeProvider,
} from "@jbrowse/react-linear-genome-view";

export default function View(props) {
  const configObject = JSON.parse(props.config);
  const { assembly, tracks, defaultSession, theme } = configObject;
  const location = props.location;
  const state = createViewState({
    assembly,
    tracks,
    defaultSession,
    location,
  });

  const jbrowseTheme =
    theme !== undefined ? createJBrowseTheme(theme) : createJBrowseTheme();

  return (
    <ThemeProvider theme={jbrowseTheme}>
      <JBrowseLinearGenomeView viewState={state} />
    </ThemeProvider>
  );
}
