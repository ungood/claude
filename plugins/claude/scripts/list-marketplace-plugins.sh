#!/usr/bin/env bash
# List all plugins available in installed marketplaces

set -euo pipefail

MARKETPLACES_DIR="${HOME}/.claude/plugins/marketplaces"

# Check if marketplaces directory exists
if [[ ! -d "$MARKETPLACES_DIR" ]]; then
    echo "No marketplaces directory found at $MARKETPLACES_DIR" >&2
    exit 1
fi

# Find all plugin.json files in the marketplaces directory
while IFS= read -r plugin_json; do
    # Get the plugin directory
    plugin_dir=$(dirname "$plugin_json")

    # Get plugin name from directory name
    plugin_name=$(basename "$plugin_dir")

    # Get marketplace name from the path
    # Path structure: ~/.claude/plugins/marketplaces/{marketplace-name}/plugins/{plugin-name}/plugin.json
    marketplace_name=$(echo "$plugin_json" | sed -E "s|$MARKETPLACES_DIR/([^/]+)/.*|\1|")

    # Output: plugin-name@marketplace-name
    echo "${plugin_name}@${marketplace_name}"
done < <(find "$MARKETPLACES_DIR" -type f -name "plugin.json" -path "*/plugins/*/plugin.json")
