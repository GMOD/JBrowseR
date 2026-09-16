// side-effect imports of assets the bundler handles but tsc has no types for
declare module '@fontsource/roboto'
declare module '@jbrowse/react-app2/styles.css'

declare module '*?worker&inline' {
  const WorkerFactory: new () => Worker
  export default WorkerFactory
}

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
    addCustomMessageHandler?(
      type: string,
      handler: (message: UpdateMessage) => void,
    ): void
  }
}

interface UpdateMessage {
  id: string
  options: Record<string, unknown>
}
