# JBrowser 0.8.1

This PR consists of updates to the JS side of the package:

- Upgrades `@jbrowse/react-linear-genome-view` to latest release (1.3.2). This includes:
  - new SVG export feature! 📸
  - a fix for better supporting Dialog components in the UI 🔨
  - performance improvements 🚀
  - better theming support (you can now change the colors of the bases!) 🎨
- Updates the internal React components in the package based on new API changes to the React LGV

There are no changes to the R interface.

# JBrowseR 0.8.0

* Added the `track_data_frame()` track type. This makes it possible to create JB2 tracks directly
from R data frames without any files.
* Updated all views to now send Shiny messages to `input$selectedFeature` recorded what feature was
clicked on. Check out the new example app `bookmark_app.R` for a demo!

# JBrowseR 0.7.1

* Updated URLS in Description to reflect new home in GMOD Github organization.
* Upgraded to @jbrowse/react-linear-genome-view version 1.0.4 (fixes issues with Safari and iOS compatibility).

# JBrowseR 0.7.0

* Initial package release!
