# Feature selection from JBrowseRApp

**Done in 0.12.0.** `createApp` grew `SessionObservers` (`onFeatureSelect`,
`onLocationChange`, `onSessionChange`), so the app widget now reports
`_selected_feature` and `_location` like the single-view one. What follows was
the state before that landed, kept for the reasoning about reaching past the
controller.

`JBrowseR()` reports clicks via `onFeatureSelect`; `JBrowseRApp()` reports
nothing, because `createApp` in `@jbrowse/react-app2` exposes no such option.
The anywidget gets at it by autorunning on the session directly (see
`src/app.ts`), which the htmlwidget can't do without reaching past the
controller API.

The clean fix is upstream: give `createApp` the same `onFeatureSelect` /
`onLocationChange` options `createLinearGenomeView` has. Then both embeddings
stop being special cases.
