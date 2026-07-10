// node:stream/web -> browser globals (WHATWG streams are global in browsers).
// stream-browserify has no /web subpath, so map it here instead.
export const ReadableStream = globalThis.ReadableStream
export const WritableStream = globalThis.WritableStream
export const TransformStream = globalThis.TransformStream
export const ByteLengthQueuingStrategy = globalThis.ByteLengthQueuingStrategy
export const CountQueuingStrategy = globalThis.CountQueuingStrategy
