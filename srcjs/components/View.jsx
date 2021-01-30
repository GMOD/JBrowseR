import {
  createViewState,
  createJBrowseTheme,
  JBrowseLinearGenomeView,
  ThemeProvider,
} from "@jbrowse/react-linear-genome-view";

const theme = createJBrowseTheme();

export default function View(props) {
  // create object of state options with only those
  // passed as props
  const stateOpts = {};
  for (const [key, value] of Object.entries(props)) {
    // parse the string of JSON config
    stateOpts[key] = JSON.parse(value);
  }
  console.log({ stateOpts });
  const state = createViewState(stateOpts);

  return (
    <ThemeProvider theme={theme}>
      <JBrowseLinearGenomeView viewState={state} />
    </ThemeProvider>
  );
}
