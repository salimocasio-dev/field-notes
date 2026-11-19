#!/bin/bash
# Line and branch coverage of historia/palabras.js over every sequence in both time zones (c8, fetched by npx into a temp folder).
#   bash coqui/tool/ref/progress/coverage.sh
# It runs make.mjs, so it also rewrites coqui/ref/progress/ (byte-identical to a plain run).
set -euo pipefail
cd "$(dirname "$0")/../../../.."
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
npm install --silent --no-save --prefix "$T/c8" c8@10.1.3 >/dev/null
"$T/c8/node_modules/.bin/c8" --temp-directory "$T/raw" --reports-dir "$T/rep" --all=false --include historia/palabras.js \
  --reporter text --reporter json-summary node coqui/tool/ref/progress/make.mjs
node -e 'const s=require(process.argv[1]).total;console.log(`palabras.js: lines ${s.lines.covered}/${s.lines.total}, branches ${s.branches.covered}/${s.branches.total}, functions ${s.functions.covered}/${s.functions.total}`)' "$T/rep/coverage-summary.json"
