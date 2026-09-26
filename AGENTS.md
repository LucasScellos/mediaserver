# AGENTS.md

Context for AI agents working on this repo. Human docs: [README.md](README.md).

## What this is

A single-user home media server: Transmission downloads from a private tracker, Plex plays the
files on the TV. Two containers, one compose file, a few shell scripts. The owner wants it
**simple to use**: prefer a setting or a script over a new service.

## Hardware (intended)

| Part | Details | Why it matters |
|---|---|---|
| Board | Raspberry Pi 4 Model B, 4 GB, aarch64 | No hardware transcoding in Plex; 4 cores are enough to serve files, not to convert video |
| Case | Argon ONE (v1, no M.2 slot) | Fan + power button run by an MCU on I2C bus 1, address `0x1a`. Needs `dtparam=i2c_arm=on` and the `argononed` service (`make fan`). Fan curve in `/etc/argononed.conf` |
| Storage | microSD, target: Samsung EVO Plus 128 GB (2024, `MB-MC128SA`, A2) | Holds OS **and** media. SD cards wear out: suspect the card first when the Pi lags |
| Optional | USB 3 disk on a blue port, mounted at `/mnt/media` | Only if the library outgrows the card: set `DATA_DIR` in `.env` |
| Network | Wi-Fi 5 GHz (Ethernet unused), power saving disabled | |
| Power | 5 V / 3 A USB-C | `vcgencmd get_throttled` must be `0x0` |

OS: Raspberry Pi OS bookworm 64-bit, user `pi` (shell zsh), Docker + Compose v2, repo in `~/mediaserver`.

## Rules

1. **No seeding.** Transmission `ratio-limit-enabled: true`, `ratio-limit: 0`. Don't change it.
2. **No video transcoding.** Plex `TranscoderCanOnlyRemuxVideo=1`: unplayable files are refused,
   never converted. Don't suggest hardware transcoding (unsupported on Pi 4). Audio conversion
   and remux are fine (cheap).
3. **Spare the SD card.** Avoid anything that writes constantly: debug logs, Plex thumbnail /
   loudness / deep analysis, big journals, transcoding on disk (it is on a tmpfs).
4. **Container paths are fixed**: `/movies`, `/shows` (Plex libraries) and `/downloads/...`
   (Transmission torrent locations). Changing them breaks existing libraries and torrents.
   Move media by changing `DATA_DIR`, not the container paths.
5. **Settings outside git** are managed by scripts, not by hand:
   - Transmission: `scripts/tune-transmission.sh`. It stops the container first because
     Transmission rewrites `settings.json` on exit.
   - Plex: `scripts/tune-plex.sh` (Plex HTTP API, token read from `Preferences.xml`).
   - System (sysctl, journald, Wi-Fi, services): `scripts/tune-pi.sh`.
   When you change a setting on the Pi, change the script too.
6. **Public repo.** Credentials live only in `.env` (git-ignored). Don't commit passwords, tokens,
   tracker names or torrent names.
7. **Remote operations.** Never reboot while `apt`/`dpkg` runs (`pgrep -x 'apt-get|dpkg'`). Run
   long upgrades detached (`sudo systemd-run --unit=... sh -c '...; echo $? > /var/tmp/status'`)
   and wait on the status file, not on SSH: a dropped SSH session is not "finished".

## Files

| Path | Role |
|---|---|
| `docker-compose.yml` | Plex + Transmission, host networking, log rotation, `/transcode` tmpfs |
| `.env.example` | `DATA_DIR`, Transmission login. Copy to `.env` |
| `Makefile` | `up`, `down`, `restart`, `update`, `status`, `logs`, `tune`, `fan` |
| `scripts/tune-pi.sh` | Wi-Fi power save off, write-back limits, journal cap, unused services off, Docker cleanup |
| `scripts/tune-transmission.sh` | 64 MB cache, 2 active downloads, private-tracker settings, no seeding |
| `scripts/tune-plex.sh` | No video transcoding, no heavy analysis, bigger DB cache |
| `scripts/install-argon.sh` | Official Argon40 installer minus its `apt-get upgrade` and EEPROM rewrite |
| `scripts/status.sh` | One-screen health check (`make status`) |
| `docs/AUDIT-2026-09.md` | Measurements and reasoning behind the current setup |

## Checking a change

```sh
docker compose config --quiet            # compose is valid
bash -n scripts/*.sh                     # scripts parse
# on the Pi, after `git pull && make up`:
make status                              # containers up, throttled 0x0, fan service running
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:32400/identity   # Plex: 200
```

Deploy = `cd ~/mediaserver && git pull && make up` on the Pi, plus the matching `tune-*` script
when one changed. There is no CI.
