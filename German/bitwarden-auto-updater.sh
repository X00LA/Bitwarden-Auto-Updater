#!/bin/bash
# Bitwarden Desktop Auto-Updater für Debian/Ubuntu
# Benötigt: curl, jq, dpkg

set -euo pipefail

GITHUB_API="https://api.github.com/repos/bitwarden/clients/releases"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Installierte Version ermitteln
INSTALLED_VERSION=$(dpkg -l bitwarden 2>/dev/null | awk '/^ii/{print $3}' | head -1)

if [[ -z "$INSTALLED_VERSION" ]]; then
    echo "Fehler: Bitwarden ist nicht installiert." >&2
    exit 1
fi

# Neuesten Desktop-Release von GitHub holen
RELEASE_JSON=$(curl -sf "https://api.github.com/repos/bitwarden/clients/releases" \
    | jq '[.[] | select(.tag_name | startswith("desktop-"))][0]')

if [[ -z "$RELEASE_JSON" || "$RELEASE_JSON" == "null" ]]; then
    echo "Fehler: Konnte Release-Informationen nicht abrufen." >&2
    exit 1
fi

# Versionsnummer extrahieren (z.B. "desktop-v2026.3.1" -> "2026.3.1")
LATEST_VERSION=$(echo "$RELEASE_JSON" | jq -r '.tag_name' | sed 's/desktop-v//')

if [[ -z "$LATEST_VERSION" ]]; then
    echo "Fehler: Konnte aktuelle Version nicht ermitteln." >&2
    exit 1
fi

# Versionen vergleichen
if [[ "$INSTALLED_VERSION" == "$LATEST_VERSION" ]]; then
    echo "Bitwarden ist bereits aktuell (Version $INSTALLED_VERSION)."
    exit 0
fi

echo "Update gefunden: $INSTALLED_VERSION -> $LATEST_VERSION"

# .deb-Asset und sha512 aus dem Release-JSON holen
DEB_URL=$(echo "$RELEASE_JSON" | jq -r '.assets[] | select(.name | endswith("-amd64.deb")) | .browser_download_url' | head -1)
DEB_NAME=$(basename "$DEB_URL")

if [[ -z "$DEB_URL" || "$DEB_URL" == "null" ]]; then
    echo "Fehler: Kein .deb-Paket im Release gefunden." >&2
    exit 1
fi

# SHA512 aus der latest-linux.yml holen
YAML_URL=$(echo "$RELEASE_JSON" | jq -r '.assets[] | select(.name == "latest-linux.yml") | .browser_download_url')
EXPECTED_SHA=$(curl -sf "$YAML_URL" \
    | grep -A1 "$DEB_NAME" \
    | awk '/sha512:/{print $2}' | head -1)

if [[ -z "$EXPECTED_SHA" ]]; then
    echo "Fehler: SHA512-Prüfsumme konnte nicht abgerufen werden." >&2
    exit 1
fi

# .deb herunterladen
echo "Lade $DEB_NAME herunter..."
curl -fL "$DEB_URL" -o "$TMP_DIR/$DEB_NAME"

# SHA512 prüfen
ACTUAL_SHA=$(openssl dgst -sha512 -binary "$TMP_DIR/$DEB_NAME" | base64 -w0)

if [[ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]]; then
    echo "Fehler: SHA512-Prüfsumme stimmt nicht überein! Abbruch." >&2
    exit 1
fi

echo "Prüfsumme OK. Installiere..."

# Installieren
sudo dpkg -i "$TMP_DIR/$DEB_NAME"

echo "Bitwarden erfolgreich auf Version $LATEST_VERSION aktualisiert."
