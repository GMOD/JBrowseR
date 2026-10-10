#!/bin/sh
# What the htmlwidget bundle must survive from a jbrowse-components change,
# run against the sibling checkout its `link:` dependencies resolve to
# (../jbrowse-components, already `pnpm install`ed). The Bundle workflow runs
# it nightly, and jbrowse-components' downstream canary runs it against the
# commit under test, so a break shows up where it was made.
set -eu
cd "$(dirname "$0")/.."
pnpm install --frozen-lockfile=false
pnpm build

# htmlwidgets delivers each bundle as one file and nothing else: the binding
# dependency carries `all_files: FALSE`, and `selfcontained = TRUE` inlines the
# bundle where there is no script URL to resolve a sibling chunk against. A
# vite change that emits a chunk builds green and 404s at runtime.
unexpected=$(ls -A inst/htmlwidgets | grep -vxE 'JBrowseR\.js|JBrowseR\.css|JBrowseRApp\.js|JBrowseRApp\.css' || true)
if [ -n "$unexpected" ]; then
  echo "::error::vite emitted files htmlwidgets will not deliver: $unexpected"
  exit 1
fi

# No Node polyfills ship: a dependency reaching for Buffer, or a vite config
# that drops the NODE_ENV define, would surface only as a blank widget.
fail=0
for f in inst/htmlwidgets/JBrowseR.js inst/htmlwidgets/JBrowseRApp.js; do
  if grep -qE '(^|[^A-Za-z0-9_$])Buffer\.' "$f"; then
    echo "::error file=$f::Buffer is used but not polyfilled"
    fail=1
  fi
  if grep -q 'process\.env\.NODE_ENV' "$f"; then
    echo "::error file=$f::process.env.NODE_ENV was not substituted (vite define missing?)"
    fail=1
  fi
done
[ "$fail" = 0 ]

# esbuild does not typecheck, so a missing import builds and fails at runtime;
# tsc follows the linked packages into the checkout's TypeScript source.
pnpm typecheck
