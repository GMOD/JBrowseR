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

const ERROR_CLASS = 'jbrowser-error'

// A failed create* call otherwise leaves an empty div, so the R user sees a
// blank browser with the reason only in the devtools console.
function showError(el: HTMLElement, e: unknown) {
  const box = document.createElement('pre')
  box.className = ERROR_CLASS
  box.style.cssText =
    'margin:0;padding:8px;height:100%;overflow:auto;white-space:pre-wrap;' +
    'font-family:monospace;font-size:12px;color:#a00;background:#fff5f5;' +
    'border:1px solid #a00;box-sizing:border-box'
  box.textContent = `JBrowseR failed to render\n\n${e instanceof Error ? (e.stack ?? e.message) : String(e)}`
  el.appendChild(box)
}

function clearError(el: HTMLElement) {
  el.querySelectorAll(`.${ERROR_CLASS}`).forEach(node => {
    node.remove()
  })
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
          clearError(el)
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
              if (token === seq) {
                showError(el, e)
              }
            })
        },
        resize() {},
      }
    },
  })
}
