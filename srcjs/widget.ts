export interface PluginSpec {
  name: string
  url: string
}

// The payload is the create* options verbatim, except the two JSON cannot
// carry: plugins arrive as specs to load, and local files as base64
export type Payload<Options> = Omit<Options, 'plugins' | 'localFiles'> & {
  plugins?: PluginSpec[]
  localFiles?: Record<string, string>
}

function decodeBase64(base64: string) {
  const bin = atob(base64)
  const bytes = new Uint8Array(bin.length)
  for (let i = 0; i < bin.length; i++) {
    bytes[i] = bin.charCodeAt(i)
  }
  return bytes
}

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

// key-order sensitive: two renders of one R expression serialize alike, and a
// false "changed" costs only a rebuild
function sameJson(a: unknown, b: unknown) {
  return JSON.stringify(a ?? null) === JSON.stringify(b ?? null)
}

// a key the next payload dropped is present with an undefined value
function changedOptions<P extends object>(previous: P, next: P) {
  const prev = previous as Record<string, unknown>
  const nxt = next as Record<string, unknown>
  const keys = new Set([...Object.keys(prev), ...Object.keys(nxt)])
  return Object.fromEntries(
    [...keys].filter(k => !sameJson(prev[k], nxt[k])).map(k => [k, nxt[k]]),
  ) as Partial<P>
}

const ERROR_CLASS = 'jbrowser-error'

const updaters = new Map<string, (options: Record<string, unknown>) => void>()

// Shiny rejects a second handler for one message type, and both bundles can
// share a page
let handlerRegistered = false
function registerUpdateHandler() {
  if (handlerRegistered || !window.Shiny?.addCustomMessageHandler) {
    return
  }
  handlerRegistered = true
  window.Shiny.addCustomMessageHandler('jbrowser-update', message => {
    const updater = updaters.get(message.id)
    if (updater) {
      updater(message.options)
    } else {
      console.warn(`JBrowseR: no browser rendered for output "${message.id}"`)
    }
  })
}

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

export interface WidgetDefinition<P, Controller> {
  // `fail` reports a failure the returned promise cannot carry, such as an
  // assembly createLinearGenomeView resolves after returning
  build: (
    el: HTMLElement,
    payload: P,
    fail: (e: unknown) => void,
  ) => Promise<Controller>
  // apply the changed options to the live browser, or answer false to rebuild
  live: (controller: Controller, changes: Partial<P>, previous: P) => boolean
}

export function defineWidget<
  P extends object,
  Controller extends { destroy: () => void },
>(
  name: string,
  { build, live }: WidgetDefinition<P, Controller>,
) {
  window.HTMLWidgets?.widget<P>({
    name,
    type: 'output',
    factory(el) {
      let controller: Controller | undefined
      let rendered: P | undefined
      let seq = 0

      function rebuild(x: P) {
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
        registerUpdateHandler()
        // a message arriving mid-build waits for it; one aimed at a build a
        // later render superseded is dropped
        updaters.set(el.id, options => {
          building
            .then(built => {
              if (controller === built && rendered) {
                const changes = options as Partial<P>
                if (!live(built, changes, rendered)) {
                  rebuild({ ...rendered, ...changes })
                }
              }
            })
            .catch(() => {})
        })
      }

      return {
        renderValue(x) {
          if (
            controller &&
            rendered &&
            live(controller, changedOptions(rendered, x), rendered)
          ) {
            rendered = x
          } else {
            rebuild(x)
          }
        },
        resize() {},
      }
    },
  })
}
