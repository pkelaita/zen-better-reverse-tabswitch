#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
CFG="$HOME/.config/karabiner/karabiner.json"
ASSET_SRC="$DIR/zen_ctrl_backtick_only.json"
ASSET_DST="$HOME/.config/karabiner/assets/complex_modifications"

if [ ! -d "/Applications/Karabiner-Elements.app" ] && [ ! -d "$HOME/Applications/Karabiner-Elements.app" ]; then
  echo "Karabiner-Elements does not appear to be installed."
  echo "Please install it either by"
  echo "    - visiting https://karabiner-elements.pqrs.org"
  echo "    - running \"brew install --cask karabiner-elements\""
  echo "Then, run this script again."
  exit 1
fi

[ -f "$CFG" ] || {
  echo "karabiner.json not found at $CFG"
  echo "Open Karabiner-Elements once so it initializes config, then rerun."
  exit 1
}

command -v jq >/dev/null 2>&1 || { echo "jq is required"; exit 1; }
[ -f "$CFG" ] || { echo "karabiner.json not found at $CFG"; exit 1; }
[ -f "$ASSET_SRC" ] || { echo "rule JSON not found next to script ($ASSET_SRC)"; exit 1; }

mkdir -p "$ASSET_DST"
cp "$ASSET_SRC" "$ASSET_DST/"

rule="$(jq '.rules[0]' "$ASSET_SRC")"
desc="$(jq -r '.description' <<<"$rule")"

tmp="$(mktemp)"
jq --argjson rule "$rule" --arg desc "$desc" '
  .profiles |= map(
    if .selected then
      .complex_modifications |= (. // {}) |
      .complex_modifications.rules |= (
        (. // []) | map(select(.description != $desc)) + [$rule]
      )
    else
      .
    end
  )
' "$CFG" > "$tmp"

mv "$tmp" "$CFG"

echo "Installed + enabled Karabiner rule: $desc"

