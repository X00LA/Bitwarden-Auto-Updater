# Bitwarden Desktop Auto-Updater

Ein schlankes Bash-Skript, das den Bitwarden Desktop-Client auf Debian-basierten Systemen automatisch aktuell hält – ohne Snap, ohne Flatpak, ohne AppImage.

---

## Hintergrund

Bitwarden hat die Auto-Update-Funktion aus den offiziellen `.deb`-Paketen entfernt, um Nutzer in Richtung Snap und Flatpak zu drängen. Dieses Skript schließt diese Lücke: Es prüft die GitHub-Releases, vergleicht die Versionsnummer mit der installierten Version, lädt bei Bedarf das neue `.deb`-Paket herunter, verifiziert die SHA512-Prüfsumme und installiert das Update automatisch.

---

## Voraussetzungen

- Debian oder ein Debian-basiertes System (z.B. Ubuntu, Linux Mint)
- Bitwarden Desktop bereits als `.deb` installiert
- Folgende Tools müssen vorhanden sein:

| Tool | Zweck | Installation |
|------|-------|-------------|
| `curl` | API-Abfragen & Downloads | `sudo apt install curl` |
| `jq` | JSON-Parsing | `sudo apt install jq` |
| `openssl` | SHA512-Verifizierung | Auf Debian standardmäßig vorhanden |
| `dpkg` | Paketinstallation | Auf Debian standardmäßig vorhanden |

---

## Installation

1. Skript herunterladen und speichern, z.B. nach `/opt/bitwarden-updater/`:

```bash
sudo mkdir -p /opt/bitwarden-auto-updater
sudo curl -fL https://raw.githubusercontent.com/X00LA/Bitwarden-Auto-Updater/refs/heads/main/German/bitwarden-auto-updater.sh \
    -o /opt/bitwarden-auto-updater/bitwarden-auto-updater.sh
sudo chmod +x /opt/bitwarden-auto-updater/bitwarden-auto-updater.sh
```

2. Einmalig testen:

```bash
sudo /opt/bitwarden-auto-updater/bitwarden-auto-updater.sh
```

---

## Ausgabe

Das Skript gibt nur bei relevantem Anlass etwas aus:

```
# Bereits aktuell:
Bitwarden ist bereits aktuell (Version 2026.3.1).

# Update verfügbar:
Update gefunden: 2026.3.1 -> 2026.4.0
Lade Bitwarden-2026.4.0-amd64.deb herunter...
Prüfsumme OK. Installiere...
Bitwarden erfolgreich auf Version 2026.4.0 aktualisiert.

# Fehlerbeispiel:
Fehler: Kein .deb-Paket im Release gefunden.
```

Fehlermeldungen werden auf `stderr` ausgegeben und landen bei Nutzung mit Cron-Logging korrekt in der Log-Datei.

---

## Cron-Job einrichten

Crontab öffnen:

```bash
sudo crontab -e
```

Folgende Zeile hinzufügen (hier: täglich um 09:00 Uhr):

```
0 9 * * * /opt/bitwarden-auto-updater/bitwarden-auto-updater.sh >> /var/log/bitwarden-update.log 2>&1
```

Cron-Syntax-Übersicht:

```
┌───────────── Minute (0–59)
│ ┌─────────── Stunde (0–23)
│ │ ┌───────── Tag des Monats (1–31)
│ │ │ ┌─────── Monat (1–12)
│ │ │ │ ┌───── Wochentag (0–7, 0 und 7 = Sonntag)
│ │ │ │ │
0 9 * * *   →   täglich um 09:00 Uhr
0 9 * * 1   →   jeden Montag um 09:00 Uhr
0 */12 * * * →  alle 12 Stunden
```

---

## Log-Datei prüfen

```bash
cat /var/log/bitwarden-update.log
```

---

## Hinweise

- Das Skript filtert gezielt nach Releases mit dem Tag-Präfix `desktop-`, um CLI- und Browser-Releases auszuschließen.
- Die SHA512-Prüfsumme wird aus der `latest-linux.yml` im GitHub-Release abgeglichen – das Paket wird bei Nichtübereinstimmung **nicht** installiert.
- Sollte Bitwarden die Struktur ihrer GitHub-Release-Tags ändern, ist das der erste Anlaufpunkt zur Fehlersuche.

---

## Lizenz

MIT License – frei verwendbar, veränderbar und weitergeben.
