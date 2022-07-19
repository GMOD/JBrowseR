import {
  createViewState,
  JBrowseLinearGenomeView,
} from "@jbrowse/react-linear-genome-view";

import { messageShiny } from "../utils";

export default function View(props) {
  // create object of state options with only those
  // passed as props
  let theme;
  const stateOpts = {};
  for (const [key, value] of Object.entries(props)) {
    if (key === "theme") {
      theme = JSON.parse(value);
      stateOpts["configuration"] = { theme };
    } else if (key == "text_index") {
      stateOpts["aggregateTextSearchAdapters"] = [JSON.parse(value)];
    } else {
      // parse the string of JSON config
      key === "location"
        ? (stateOpts[key] = value)
        : (stateOpts[key] = JSON.parse(value));
    }
  }
  stateOpts.onChange = messageShiny;

  const state = createViewState(stateOpts);

  return <JBrowseLinearGenomeView viewState={state} />;
}
