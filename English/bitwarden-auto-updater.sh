#!/bin/bash
# Bitwarden Desktop Auto-Updater for Debian/Ubuntu
# Requires: curl, jq, dpkg

set -euo pipefail

GITHUB_API="https://api.github.com/repos/bitwarden/clients/releases"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Determine the installed version
INSTALLED_VERSION=$(dpkg -l bitwarden 2>/dev/null | awk '/^ii/{print $3}' | head -1)

if [[ -z "$INSTALLED_VERSION" ]]; then
    echo "Error: Bitwarden is not installed." >&2
    exit 1
fi

# Get the latest desktop release from GitHub
RELEASE_JSON=$(curl -sf "https://api.github.com/repos/bitwarden/clients/releases" \
    | jq '[.[] | select(.tag_name | startswith("desktop-"))][0]')

if [[ -z "$RELEASE_JSON" || "$RELEASE_JSON" == "null" ]]; then
    echo "Error: Could not retrieve release information." >&2
    exit 1
fi

# Extract version number (e.g. "desktop-v2026.3.1" -> "2026.3.1")
LATEST_VERSION=$(echo "$RELEASE_JSON" | jq -r '.tag_name' | sed 's/desktop-v//')

if [[ -z "$LATEST_VERSION" ]]; then
    echo "Error: Could not determine current version." >&2
    exit 1
fi

# Compare versions
if [[ "$INSTALLED_VERSION" == "$LATEST_VERSION" ]]; then
    echo "Bitwarden is already up-to-date (Version $INSTALLED_VERSION)."
    exit 0
fi

echo "Update found: $INSTALLED_VERSION -> $LATEST_VERSION"

# Extract the .deb asset and sha512 from the release JSON
DEB_URL=$(echo "$RELEASE_JSON" | jq -r '.assets[] | select(.name | endswith("-amd64.deb")) | .browser_download_url' | head -1)
DEB_NAME=$(basename "$DEB_URL")

if [[ -z "$DEB_URL" || "$DEB_URL" == "null" ]]; then
    echo "Error: No .deb package found in the release." >&2
    exit 1
fi

# Retrieve SHA512 from latest-linux.yml
YAML_URL=$(echo "$RELEASE_JSON" | jq -r '.assets[] | select(.name == "latest-linux.yml") | .browser_download_url')
EXPECTED_SHA=$(curl -sf "$YAML_URL" \
    | grep -A1 "$DEB_NAME" \
    | awk '/sha512:/{print $2}' | head -1)

if [[ -z "$EXPECTED_SHA" ]]; then
    echo "Error: SHA512 checksum could not be retrieved." >&2
    exit 1
fi

# Download .deb
echo "Download $DEB_NAME..."
curl -fL "$DEB_URL" -o "$TMP_DIR/$DEB_NAME"

# SHA512 check
ACTUAL_SHA=$(openssl dgst -sha512 -binary "$TMP_DIR/$DEB_NAME" | base64 -w0)

if [[ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]]; then
    echo "Fehler: SHA512-Prüfsumme stimmt nicht überein! Abbruch." >&2
    exit 1
fi

echo "Checksum OK. Installing..."

# Installing
sudo dpkg -i "$TMP_DIR/$DEB_NAME"

echo "Bitwarden successfully updated to version $LATEST_VERSION."
