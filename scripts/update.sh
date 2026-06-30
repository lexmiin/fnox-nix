#!/usr/bin/env bash
set -euo pipefail

readonly GITHUB_REPO="jdx/fnox"
readonly PACKAGE_FILE="package.nix"

targets=(
  "aarch64-darwin:aarch64-apple-darwin"
  "x86_64-darwin:x86_64-apple-darwin"
  "aarch64-linux:aarch64-unknown-linux-musl"
  "x86_64-linux:x86_64-unknown-linux-musl"
)

log() {
  printf '[fnox-nix] %s\n' "$*"
}

usage() {
  cat <<'EOF'
Usage: scripts/update.sh [--version VERSION] [--skip-build]

Options:
  --version VERSION  Update to a specific fnox version, with or without leading v.
  --skip-build       Rewrite package.nix without building the current-system package.
  --help             Show this help text.
EOF
}

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required tool: %s\n' "$1" >&2
    exit 1
  fi
}

current_version() {
  sed -n 's/.*version = "\([^"]*\)";.*/\1/p' "$PACKAGE_FILE" | head -n1
}

sri_from_hex_digest() {
  python3 - "$1" <<'PY'
import base64
import sys

digest = sys.argv[1]
if digest.startswith("sha256:"):
    digest = digest.split(":", 1)[1]

print("sha256-" + base64.b64encode(bytes.fromhex(digest)).decode())
PY
}

hash_for_asset() {
  local release_json="$1"
  local asset_name="$2"
  local digest
  local url

  digest=$(jq -r --arg name "$asset_name" '.assets[] | select(.name == $name) | .digest // empty' <<<"$release_json")
  if [[ -n "$digest" && "$digest" != "null" ]]; then
    sri_from_hex_digest "$digest"
    return
  fi

  url=$(jq -r --arg name "$asset_name" '.assets[] | select(.name == $name) | .browser_download_url // empty' <<<"$release_json")
  if [[ -z "$url" || "$url" == "null" ]]; then
    printf 'Could not find asset %s in release\n' "$asset_name" >&2
    exit 1
  fi

  nix hash convert --hash-algo sha256 --to sri "$(nix-prefetch-url "$url")"
}

rewrite_package() {
  local version="$1"
  shift

  python3 - "$PACKAGE_FILE" "$version" "$@" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
version = sys.argv[2]
updates = dict(arg.split("=", 1) for arg in sys.argv[3:])

text = path.read_text()
text = re.sub(r'version = "[^"]+";', f'version = "{version}";', text, count=1)

for system, hash_value in updates.items():
    pattern = rf'({re.escape(system)} = \{{\n\s+target = "[^"]+";\n\s+hash = ")[^"]+(";\n\s+\}};)'
    text, count = re.subn(pattern, rf'\g<1>{hash_value}\2', text, count=1)
    if count != 1:
        raise SystemExit(f"Could not update hash for {system}")

path.write_text(text)
PY
}

target_version=""
skip_build=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      target_version="${2#v}"
      shift 2
      ;;
    --skip-build)
      skip_build=true
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -f flake.nix || ! -f "$PACKAGE_FILE" ]]; then
  printf 'Run this script from the fnox-nix repository root.\n' >&2
  exit 1
fi

require_tool gh
require_tool jq
require_tool nix
require_tool python3

if [[ -z "$target_version" ]]; then
  release_json=$(gh api "repos/${GITHUB_REPO}/releases/latest")
  target_version=$(jq -r '.tag_name' <<<"$release_json")
  target_version="${target_version#v}"
else
  release_json=$(gh api "repos/${GITHUB_REPO}/releases/tags/v${target_version}")
fi

current=$(current_version)
log "current version: ${current}"
log "target version: ${target_version}"

if [[ "$current" == "$target_version" ]]; then
  log "already up to date"
  exit 0
fi

updates=()
for pair in "${targets[@]}"; do
  system="${pair%%:*}"
  target="${pair#*:}"
  asset_name="fnox-${target}.tar.gz"
  log "hashing ${asset_name}"
  updates+=("${system}=$(hash_for_asset "$release_json" "$asset_name")")
done

rewrite_package "$target_version" "${updates[@]}"
log "updated ${PACKAGE_FILE}"

if [[ "$skip_build" == false ]]; then
  log "building current-system package"
  nix build .#fnox --print-build-logs
  ./result/bin/fnox --version
fi

log "done"
