# JBrowse 0.9.1

- Updated `@jbrowse/react-linear-genome-view` to latest release (2.0.1). Check out the [JB2 release notes](https://jbrowse.org/jb2/blog/2022/07/13/v2.0.1-release/) to learn about all of the features!
- Added a new function `text_index()` to provide support for text search.

# JBrowseR 0.9.0

- Updated `@jbrowse/react-linear-genome-view` to latest release (1.4.4). Check out the [JB2 release notes](https://jbrowse.org/jb2/blog/2021/09/14/v1.4.4-release/) to learn about all of the features!
- Fixed the code example for `track_wiggle()`.
- Updated the URL for the hg38 to fix the CORS error from the old source.

# JBrowseR 0.8.1

This release consists of updates to the JS side of the package:

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
