---
name: per-view-location-door-in-jbrowserapp
description: JBrowseRApp() has no per-view location door; update_jbrowse() reaches views only through session or a rebuild, until upstream adds setViewLocation(id, loc).
---

# Per-view location door in JBrowseRApp

`JBrowseRApp()` has no per-view location door: `update_jbrowse()` reaches it only
through `session`, or a rebuild. `ManagedView` carries an `id` and `createApp`
defaults one per view (`viewsToSession`), so `setViewLocation(id, loc)` is
well-defined whenever someone wants to add it upstream.
