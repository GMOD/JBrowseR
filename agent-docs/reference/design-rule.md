# The design rule now in force

**A widget's JS options are its API.** `JBrowseR(...)` sends
`createLinearGenomeView`'s options verbatim and `JBrowseRApp(...)` sends
`createApp`'s, under JBrowse's camelCase names. R names none of them: no
per-key formals, no reshaping, so an option JBrowse adds needs nothing here. The
formals after `...` are only what JSON cannot carry or htmlwidgets needs:
`local_files` (R reads the bytes), `width`, `height`, `elementId`. Every option
is named; an unnamed one errors.

The package exports these names:

| | why it survives |
|---|---|
| `JBrowseR`, `JBrowseRApp` | the widgets |
| `JBrowseROutput`, `renderJBrowseR` | the Shiny bindings |
| `JBrowseRAppOutput`, `renderJBrowseRApp` | the app's, which cannot be shared (htmlwidgets dispatches on the element's class) |
| `track_data_frame` | a data frame is not JSON |
| `update_jbrowse` | changing a rendered browser without re-running its render |

0.13.0 cut `theme=`, `text_search=` and `config=`: each renamed or reshaped a
JBrowse option (`configuration.theme`, `aggregateTextSearchAdapters`, a
`do.call`). Before that, 0.11.0 cut the config builders (`assembly`, `track`,
`theme`, `view`, ...). If you are about to add an argument or helper that shapes
an option, put the list in the docs instead.

`update_jbrowse(outputId, ..., domain)` names its Shiny session `domain`
because `session` is a JBrowseRApp option.

`tests/testthat/test-docs.R` checks every documented call's argument names
against the upstream option interfaces, parsed out of the sibling
jbrowse-components checkout, and skips that half when the checkout is absent.
