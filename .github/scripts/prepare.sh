#!/usr/bin/env bash
set -euo pipefail

# prepare.sh for gbdev/rgbds-www
# Docusaurus 3.7.0, Yarn 1 (classic), Node 20
# Clones the repo and installs dependencies.
# Does NOT run write-translations or build.

REPO_URL="https://github.com/gbdev/rgbds-www"
BRANCH="master"
REPO_DIR="source-repo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# --- Clone (skip if already exists) ---
if [ ! -d "$REPO_DIR" ]; then
  git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR"

# --- Package manager: Yarn 1 (classic) ---
if ! command -v yarn &>/dev/null; then
  npm install -g yarn
fi
echo "Yarn: $(yarn --version)"

# Frozen lockfile for reproducibility; fall back if it fails
yarn install --frozen-lockfile || yarn install

# --- Apply fixes.json if present ---
FIXES_JSON="$SCRIPT_DIR/fixes.json"
if [ -f "$FIXES_JSON" ]; then
  echo "[INFO] Applying content fixes..."
  node -e "
const fs = require('fs');
const path = require('path');
const fixes = JSON.parse(fs.readFileSync('$FIXES_JSON', 'utf8'));
for (const [file, ops] of Object.entries(fixes.fixes || {})) {
  if (!fs.existsSync(file)) { console.log('  skip (not found):', file); continue; }
  let content = fs.readFileSync(file, 'utf8');
  for (const op of ops) {
    if (op.type === 'replace' && content.includes(op.find)) {
      content = content.split(op.find).join(op.replace || '');
      console.log('  fixed:', file, '-', op.comment || '');
    }
  }
  fs.writeFileSync(file, content);
}
for (const [file, cfg] of Object.entries(fixes.newFiles || {})) {
  const c = typeof cfg === 'string' ? cfg : cfg.content;
  fs.mkdirSync(path.dirname(file), {recursive: true});
  fs.writeFileSync(file, c);
  console.log('  created:', file);
}
"
fi

echo "[DONE] Repository is ready for docusaurus commands."
