import {
  createViewState,
  createJBrowseTheme,
  JBrowseLinearGenomeView,
  ThemeProvider,
} from "@jbrowse/react-linear-genome-view";

const theme = createJBrowseTheme();

export default function View(props) {
  console.log({ props });
  const state = createViewState({
    assembly: props.assembly,
    tracks: props.tracks,
    location: props.location,
    defaultSession: props.defaultSession,
  });

  return (
    <ThemeProvider theme={theme}>
      <JBrowseLinearGenomeView viewState={state} />
    </ThemeProvider>
  );
}