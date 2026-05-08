# Bitwarden Desktop Auto-Updater

A lightweight Bash script that automatically keeps the Bitwarden Desktop client up to date on Debian-based systems – without Snap, without Flatpak, without AppImage.

---

## Background

Bitwarden removed the auto-update functionality from their official `.deb` packages to push users towards Snap and Flatpak. This script closes that gap: it checks the GitHub releases, compares the version number with the installed version, downloads the new `.deb` package if needed, verifies the SHA512 checksum, and installs the update automatically.

---

## Requirements

- Debian or a Debian-based system (e.g. Ubuntu, Linux Mint)
- Bitwarden Desktop already installed as a `.deb` package
- The following tools must be available:

| Tool | Purpose | Installation |
|------|---------|-------------|
| `curl` | API requests & downloads | `sudo apt install curl` |
| `jq` | JSON parsing | `sudo apt install jq` |
| `openssl` | SHA512 verification | Included with Debian by default |
| `dpkg` | Package installation | Included with Debian by default |

---

## Installation

1. Download and save the script, e.g. to `/opt/bitwarden-updater/`:

```bash
sudo mkdir -p /opt/bitwarden-auto-updater
sudo curl -fL https://raw.githubusercontent.com/X00LA/Bitwarden-Auto-Updater/refs/heads/main/English/bitwarden-auto-updater.sh \
    -o /opt/bitwarden-auto-updater/bitwarden-auto-updater.sh
sudo chmod +x /opt/bitwarden-auto-updater/bitwarden-auto-updater.sh
```

2. Run a one-time test:

```bash
sudo /opt/bitwarden-auto-updater/bitwarden-auto-updater.sh
```

---

## Output

The script only produces output when relevant:

```
# Already up to date:
Bitwarden is already up to date (Version 2026.3.1).

# Update available:
Update found: 2026.3.1 -> 2026.4.0
Downloading Bitwarden-2026.4.0-amd64.deb...
Checksum OK. Installing...
Bitwarden successfully updated to version 2026.4.0.

# Error example:
Error: No .deb package found in release.
```

Error messages are written to `stderr` and will be correctly captured in the log file when using Cron logging.

---

## Setting Up a Cron Job

Open the crontab:

```bash
sudo crontab -e
```

Add the following line (here: daily at 09:00 AM):

```
0 9 * * * /opt/bitwarden-auto-updater/bitwarden-auto-updater.sh >> /var/log/bitwarden-update.log 2>&1
```

Cron syntax overview:

```
┌───────────── Minute (0–59)
│ ┌─────────── Hour (0–23)
│ │ ┌───────── Day of month (1–31)
│ │ │ ┌─────── Month (1–12)
│ │ │ │ ┌───── Day of week (0–7, 0 and 7 = Sunday)
│ │ │ │ │
0 9 * * *    →   daily at 09:00 AM
0 9 * * 1    →   every Monday at 09:00 AM
0 */12 * * * →   every 12 hours
```

---

## Checking the Log File

```bash
cat /var/log/bitwarden-update.log
```

---

## Notes

- The script specifically filters for releases with the tag prefix `desktop-` to exclude CLI and browser extension releases.
- The SHA512 checksum is verified against the `latest-linux.yml` file in the GitHub release – the package will **not** be installed if the checksum does not match.
- Should Bitwarden change the structure of their GitHub release tags, that is the first place to look when troubleshooting.

---

## License

MIT License – free to use, modify, and distribute.
