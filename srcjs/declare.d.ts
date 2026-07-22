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
  }
}
