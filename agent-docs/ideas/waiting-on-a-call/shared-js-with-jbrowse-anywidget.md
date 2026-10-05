---
name: shared-js-with-jbrowse-anywidget
description: srcjs/ and jbrowse-anywidget/src/ have converged; share the vite shim knowledge only if a third embedding appears or the configs drift in substance.
---

# Shared JS between JBrowseR and jbrowse-anywidget

`srcjs/` and `~/src/jbrowse-anywidget/src/` have converged: `stream-web-shim.ts`
is byte-identical, and the two `vite.config.js` files differ only in output
format (IIFE vs ESM) and comment wording. The entries genuinely differ — one
talks to `renderValue`, the other to a traitlet model — so there is less to share
than it looks.

Not worth a shared npm package at this size. What is actually at risk is the
hard-won shim knowledge in the vite config (the `stream/web` interception, the
react/mobx dedupe for linked monorepo packages); if that drifts and only one copy
gets the fix, the other breaks in a way that is annoying to rediscover. Revisit
if a third embedding appears, or if the configs drift in substance rather than
prose.
