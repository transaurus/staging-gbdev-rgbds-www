#!/usr/bin/env bash
set -euo pipefail

# rebuild.sh for gbdev/rgbds-www
# Docusaurus 3.7.0, Yarn 1 (classic), Node 20
# Runs on existing source tree (no clone). Installs deps and builds.
# Does NOT run write-translations.

# --- Node version ---
export NVM_DIR="${HOME}/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  # shellcheck disable=SC1091
  source "$NVM_DIR/nvm.sh"
  nvm use 20 2>/dev/null || nvm install 20
else
  if command -v fnm &>/dev/null; then
    eval "$(fnm env)"
    fnm use 20 2>/dev/null || fnm install 20
  fi
fi

echo "Node: $(node --version)"
echo "npm:  $(npm --version)"

# --- Package manager: Yarn 1 (classic) ---
if ! command -v yarn &>/dev/null; then
  npm install -g yarn
fi
echo "Yarn: $(yarn --version)"

yarn install --frozen-lockfile || yarn install

# --- Build ---
yarn build

# --- Verify build output ---
if [ ! -d "build" ] || [ -z "$(ls -A build)" ]; then
  echo "ERROR: build/ directory is missing or empty"
  exit 1
fi
echo "Build succeeded. Files in build/: $(find build -type f | wc -l)"

echo "[DONE] Build complete."
