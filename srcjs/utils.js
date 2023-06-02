/**
 * The function for using Shiny's global
 * object to send messages from JS back to
 * the app. Used for sending what feature
 * was selected in the JB2.
 *
 * @param patch The JSON patch received from
 * the LGV ViewState with what was changed.
 */
export function messageShiny(patch) {
  if (typeof Shiny === undefined) {
    return
  }

  const { path, value } = patch

  if (path.endsWith('featureData')) {
    Shiny.setInputValue('selectedFeature', value)
  } else if (path.endsWith('Feature')) {
    if (value) {
      const { featureData } = value
      if (featureData) {
        Shiny.setInputValue('selectedFeature', featureData)
      }
    }
  }
}
