export interface PluginSpec {
  name: string
  url: string
}

// The widget payload htmlwidgets hands renderValue is the create* options
// verbatim — the R helpers produce that camelCase shape — with two exceptions,
// both of them things JSON cannot carry: plugins arrive as [{name,url}] specs
// loaded at runtime (R can't ship constructors), and local files arrive as
// base64 (htmlwidgets has no binary channel, unlike ipywidgets' buffers, so a
// raw vector rides as the string jsonlite makes of it).
export type Payload<Options> = Omit<Options, 'plugins' | 'localFiles'> & {
  plugins?: PluginSpec[]
  localFiles?: Record<string, string>
}

// Base64 back to bytes. Written as a loop rather than
// `Uint8Array.from(bin, c => c.charCodeAt(0))` because these are whole data
// files — a per-character callback over tens of millions of them is worth
// avoiding on the render path.
function decodeBase64(base64: string) {
  const bin = atob(base64)
  const bytes = new Uint8Array(bin.length)
  for (let i = 0; i < bin.length; i++) {
    bytes[i] = bin.charCodeAt(i)
  }
  return bytes
}

/**
 * Decode the payload's `localFiles` into the `name -> bytes` the view takes.
 *
 * The bytes are read by byte range once they are in the browser, so an indexed
 * file stays indexed — but getting them there costs the base64 inflation and
 * puts the whole file in the document. That ceiling is why this is for a file
 * on the analyst's own machine rather than for hosted data.
 */
export function decodeLocalFiles(files: Record<string, string> | undefined) {
  return files
    ? Object.fromEntries(
        Object.entries(files).map(([name, base64]) => [
          name,
          decodeBase64(base64),
        ]),
      )
    : undefined
}

/**
 * Whether two payload fields state the same thing.
 *
 * Key order counts, because the cheap comparison is the whole point and the
 * payload is R's own JSON: two renders of one expression serialize their lists
 * in the same order, so the only thing order-sensitivity costs is a rebuild
 * where a reconcile would have done — which is what every render did before
 * there was a reconcile. A false "unchanged" would leave a stale browser
 * looking correct, so the bias goes this way deliberately.
 */
export function sameJson(a: unknown, b: unknown) {
  return JSON.stringify(a ?? null) === JSON.stringify(b ?? null)
}

const ERROR_CLASS = 'jbrowser-error'

// Live browsers by output element id, so an `update_location()` call from the
// R server reaches the one it names. The value takes the call rather than the
// controller, because the controller may not exist yet: `build` is async, so an
// `observe()` that fires at startup races the first render. Holding the
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

// A failed build otherwise leaves an empty div, so the R user sees a blank
// browser with the reason only in the devtools console.
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

interface WidgetHooks<P, Controller> {
  /**
   * Bring the live browser to the next payload, answering whether it could.
   * A `false` — or no hook at all — falls back to destroying it and building
   * again, which is what every render used to do.
   */
  absorb?: (controller: Controller, previous: P, next: P) => boolean
  /**
   * How this widget answers an `update_location()` call. Omitted by a widget
   * whose controller has nothing safe to drive live — an unknown method is the
   * widget's own error to report, since only it knows what it offers.
   */
  dispatch?: (controller: Controller, call: ProxyCall) => void
}

// Both widgets are the same htmlwidgets shell around a create* call, with the
// last payload winning (renderValue fires repeatedly in Shiny).
export function defineWidget<P, Controller extends { destroy: () => void }>(
  name: string,
  // `fail` is how a build reports a failure that its own promise cannot carry:
  // createLinearGenomeView returns synchronously and resolves the assembly
  // inside itself, so a genome that will not resolve never reaches this promise
  // at all. Without it the widget is a blank box and the reason is console-only.
  build: (
    el: HTMLElement,
    payload: P,
    fail: (e: unknown) => void,
  ) => Promise<Controller>,
  { absorb, dispatch }: WidgetHooks<P, Controller> = {},
) {
  window.HTMLWidgets?.widget<P>({
    name,
    type: 'output',
    factory(el) {
      let controller: Controller | undefined
      let rendered: P | undefined
      let seq = 0
      return {
        renderValue(x) {
          // The live path: in Shiny every reactive read feeding the widget
          // re-renders it, and rebuilding refetches every track and throws away
          // the zoom, track order, scroll position and selection the user
          // built. A controller that can reconcile the difference keeps them.
          if (controller && rendered && absorb?.(controller, rendered, x)) {
            rendered = x
            return
          }
          const token = ++seq
          const fail = (e: unknown) => {
            console.error(e)
            if (token === seq) {
              showError(el, e)
            }
          }
          controller?.destroy()
          controller = undefined
          rendered = x
          clearError(el)
          const building = build(el, x, fail)
          building
            .then(built => {
              if (token === seq) {
                controller = built
              } else {
                built.destroy()
              }
            })
            .catch(fail)
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
