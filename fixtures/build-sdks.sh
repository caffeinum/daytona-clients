#!/usr/bin/env bash
# Builds the TypeScript and Python SDKs (with their generated API clients) from
# this checkout into $1, for firegoat's install: steps.
set -euo pipefail

out="${1:?usage: build-sdks.sh <out-dir>}"
repo="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo"

if command -v yarn >/dev/null; then
  yarn() { command yarn "$@"; }
elif command -v corepack >/dev/null; then
  export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
  yarn() { corepack yarn "$@"; }
else
  echo "build-sdks.sh: needs yarn 4: run inside 'nix develop .#node', or put a node with corepack on PATH" >&2
  exit 1
fi
command -v uv >/dev/null || { echo "build-sdks.sh: needs uv on PATH" >&2; exit 1; }

[ -d node_modules ] || yarn install --immutable
yarn nx run sdk-typescript:build
for pkg in api-client toolbox-api-client analytics-api-client sdk-typescript; do
  npm pack -s "./dist/$pkg" --pack-destination "$out" >/dev/null
done

for pkg in api-client-python api-client-python-async \
  toolbox-api-client-python toolbox-api-client-python-async \
  analytics-api-client-python analytics-api-client-python-async sdk-python; do
  (cd "$pkg" && uv build -q --wheel --out-dir "$out")
done
