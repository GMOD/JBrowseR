// side-effect imports of assets the bundler handles but tsc has no types for
declare module '@fontsource/roboto'
declare module '@jbrowse/react-app2/styles.css'

// The two htmlwidgets globals htmlwidgets/Shiny inject at runtime. `x` is the
// widget payload the R side serializes; each widget narrows it to its own shape.
interface Window {
  HTMLWidgets?: {
    widget<T = unknown>(definition: {
      name: string
      type: string
      factory(el: HTMLElement): {
        renderValue(x: T): void
        resize(): void
      }
    }): void
  }
  Shiny?: {
    setInputValue(id: string, value: unknown): void
    // Present only in a Shiny page; an Rmd or console widget has a Shiny
    // global with neither method, which is why both are optional.
    addCustomMessageHandler?(
      type: string,
      handler: (message: ProxyCall) => void,
    ): void
  }
}

// What `update_*()` sends from the R server. `id` is the output element's id,
// already namespaced by the R side when the caller is inside a Shiny module.
interface ProxyCall {
  id: string
  method: string
  args?: Record<string, unknown>
}
