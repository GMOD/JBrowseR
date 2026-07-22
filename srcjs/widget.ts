export interface PluginSpec {
  name: string
  url: string
}

// The widget payload htmlwidgets hands renderValue is the create* options
// verbatim — the R helpers produce that camelCase shape — except plugins arrive
// as [{name,url}] specs loaded at runtime (R can't ship constructors).
export type Payload<Options> = Omit<Options, 'plugins'> & {
  plugins?: PluginSpec[]
}

// Both widgets are the same htmlwidgets shell around an async create* call:
// destroy the previous browser, build the next one, and let the last payload win
// (renderValue can fire repeatedly in Shiny).
export function defineWidget<P, Controller extends { destroy: () => void }>(
  name: string,
  build: (el: HTMLElement, payload: P) => Promise<Controller>,
) {
  window.HTMLWidgets?.widget<P>({
    name,
    type: 'output',
    factory(el) {
      let controller: Controller | undefined
      let seq = 0
      return {
        renderValue(x) {
          const token = ++seq
          controller?.destroy()
          controller = undefined
          build(el, x)
            .then(built => {
              if (token === seq) {
                controller = built
              } else {
                built.destroy()
              }
            })
            .catch((e: unknown) => {
              console.error(e)
            })
        },
        resize() {},
      }
    },
  })
}
