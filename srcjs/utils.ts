/**
 * The function for using Shiny's global
 * object to send messages from JS back to
 * the app. Used for sending what feature
 * was selected in the JB2.
 *
 * @param patch The JSON patch received from
 * the LGV ViewState with what was changed.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function messageShiny(patch: any) {
  if (typeof Shiny === 'undefined') {
    return
  }

  const { path, value } = patch

  if (path.endsWith('featureData')) {
    Shiny.setInputValue('selectedFeature', value)
  } else if (path.endsWith('Feature') && value) {
    const { featureData } = value
    if (featureData) {
      Shiny.setInputValue('selectedFeature', featureData)
    }
  }
}
