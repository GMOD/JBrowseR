import {
  createViewState,
  createJBrowseTheme,
  JBrowseLinearGenomeView,
  ThemeProvider,
} from "@jbrowse/react-linear-genome-view";

export default function View(props) {
  // create object of state options with only those
  // passed as props
  let theme;
  const stateOpts = {};
  for (const [key, value] of Object.entries(props)) {
    if (key === "theme") {
      theme = JSON.parse(value);
    } else {
      // parse the string of JSON config
      key === "location"
        ? (stateOpts[key] = value)
        : (stateOpts[key] = JSON.parse(value));
    }
  }

  const jbrowseTheme =
    theme !== undefined ? createJBrowseTheme(theme) : createJBrowseTheme();
  const state = createViewState(stateOpts);

  return (
    <ThemeProvider theme={jbrowseTheme}>
      <JBrowseLinearGenomeView viewState={state} />
    </ThemeProvider>
  );
}
