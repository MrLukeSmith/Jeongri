#!/usr/bin/env bash
set -euo pipefail

LEVEL="${1:-patch}"

current=$(jq -r '.version' .claude-plugin/plugin.json)

IFS='.' read -r major minor patch <<< "$current"

case "$LEVEL" in
  major) new="$((major + 1)).0.0" ;;
  minor) new="$major.$((minor + 1)).0" ;;
  patch) new="$major.$minor.$((patch + 1))" ;;
  *) echo "Usage: $0 {patch|minor|major}" >&2; exit 1 ;;
esac

jq --arg v "$new" '.version = $v' .claude-plugin/plugin.json > .claude-plugin/plugin.json.tmp
mv .claude-plugin/plugin.json.tmp .claude-plugin/plugin.json

jq --arg v "$new" '.plugins[0].version = $v' .claude-plugin/marketplace.json > .claude-plugin/marketplace.json.tmp
mv .claude-plugin/marketplace.json.tmp .claude-plugin/marketplace.json

jq --arg v "$new" '.version = $v' gemini-extension.json > gemini-extension.json.tmp
mv gemini-extension.json.tmp gemini-extension.json

echo "Bumped version to $new"
