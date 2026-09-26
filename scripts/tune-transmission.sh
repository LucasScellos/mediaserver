#!/usr/bin/env bash
# Applies Pi-friendly Transmission settings. Safe to run again.
# Transmission rewrites settings.json when it stops, so the container is stopped first.
set -euo pipefail
cd "$(dirname "$0")/.."

SETTINGS=config/transmission/settings.json
[ -f "$SETTINGS" ] || { echo "No $SETTINGS yet: run 'make up' once first."; exit 1; }

docker compose stop transmission
cp "$SETTINGS" "$SETTINGS.bak-$(date +%Y%m%d-%H%M%S)"

python3 - "$SETTINGS" <<'EOF'
import json, sys
path = sys.argv[1]
s = json.load(open(path))
s.update({
    # 64 MB write cache (was 4): pieces are written in big chunks instead of
    # thousands of small random writes, which is what makes the SD card choke.
    "cache-size-mb": 64,
    # Two downloads at a time; more just fight over the disk.
    "download-queue-size": 2,
    "peer-limit-global": 120,
    "peer-limit-per-torrent": 40,
    # Private tracker only: DHT/PEX/LPD are unused, uTP costs CPU.
    "dht-enabled": False,
    "pex-enabled": False,
    "lpd-enabled": False,
    "utp-enabled": False,
    # Default destination: a .torrent dropped in watch/ lands straight in Plex "Films".
    # For a series, pick /downloads/shows in the "add torrent" dialog.
    "download-dir": "/downloads/movies",
    "incomplete-dir": "/downloads/incomplete",
    "incomplete-dir-enabled": True,
    # No seeding: a torrent stops as soon as it is complete.
    "ratio-limit-enabled": True,
    "ratio-limit": 0,
    "idle-seeding-limit-enabled": False,
})
json.dump(s, open(path, "w"), indent=4, sort_keys=True)
print("settings.json updated")
EOF

DATA_DIR=$(grep -E '^DATA_DIR=' .env 2>/dev/null | cut -d= -f2- || true)
DATA_DIR=${DATA_DIR:-./downloads}
mkdir -p "$DATA_DIR/movies" "$DATA_DIR/shows" "$DATA_DIR/incomplete"
docker compose start transmission
