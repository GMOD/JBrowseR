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

// Live browsers by output element id, so a `jbrowse_proxy()` call from the R
// server reaches the one it names. The value takes the call rather than being
// the controller, because the controller may not exist yet: `build` is async, so
// an `observe()` that fires at startup races the first render. Holding the
// promise instead of the resolved value makes that ordinary rather than a
// dropped call.
const callers = new Map<string, (call: ProxyCall) => void>()

// One handler for every widget in the page, registered on first use. Shiny
// rejects a duplicate registration for the same message type, and the two
// widget bundles are separate entry points that can both be on a page.
let handlerRegistered = false
function registerProxyHandler() {
  if (handlerRegistered || !window.Shiny?.addCustomMessageHandler) {
    return
  }
  handlerRegistered = true
  window.Shiny.addCustomMessageHandler('jbrowser-call', call => {
    const caller = callers.get(call.id)
    if (caller) {
      caller(call)
    } else {
      // The likeliest cause by far is an id that is not the output's — a bare
      // one from inside a module, or a typo — and silence there costs an
      // afternoon.
      console.warn(
        `JBrowseR: no browser rendered for output "${call.id}", ignoring ${call.method}`,
      )
    }
  })
}

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
  // How this widget answers a `jbrowse_proxy()` call. Omitted by a widget whose
  // controller has nothing safe to drive live — an unknown method is the
  // widget's own error to report, since only it knows what it offers.
  dispatch?: (controller: Controller, call: ProxyCall) => void,
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
          const building = build(el, x)
          building
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
          if (dispatch) {
            registerProxyHandler()
            // Re-registered per render so the entry closes over THIS build. A
            // call that lands mid-build waits for it; one that lands after a
            // rebuild superseded this browser is dropped by the identity check,
            // rather than driving a controller that was already destroyed.
            callers.set(el.id, call => {
              building
                .then(built => {
                  if (controller === built) {
                    dispatch(built, call)
                  }
                })
                .catch(() => {
                  // the build's own catch above already reported it
                })
            })
          }
        },
        resize() {},
      }
    },
  })
}
