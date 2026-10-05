# Reactivity: updating a browser without rebuilding it

**Done**, and by the route the last note called "a much larger change": the
components became declarative upstream rather than each embedding growing
imperative handles. `LinearGenomeViewController` is `whenReady` / `update(state)`
/ `destroy`, `update` takes the whole wanted state, and it reconciles — so R,
Python and plain JS get the same answer. See [controller-update.md](controller-update.md) for what that means
here.

Kept because the reasoning was the blocker and is worth not re-deriving: the
question that stopped this was "what should an update do to a track the user
opened by hand, or a view layout they rearranged?", and `reconcileTracks` in
`packages/product-core` answers it — the host's list is the complete wanted set
of *its* tracks, opened if absent and closed if dropped, and the session's own
`getTrackById` keeps a config the user already has from being shadowed. The
echo problem the anywidget hit (`onLocationChange` writing back into the trait
it mirrors) does not arise in htmlwidgets, because R holds no two-way binding:
the payload flows one way and `input$<id>_location` is a read-back nothing feeds
back automatically.
