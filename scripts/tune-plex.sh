#!/usr/bin/env bash
# Applies Pi-friendly Plex settings through the Plex API. Safe to run again.
# Plex keeps its settings in config/ (not in git), so this script is the source of truth.
set -euo pipefail
cd "$(dirname "$0")/.."

PREFS="config/plex/Library/Application Support/Plex Media Server/Preferences.xml"
[ -f "$PREFS" ] || { echo "No Plex config yet: run 'make up' and sign in to Plex first."; exit 1; }
TOKEN=$(grep -oE 'PlexOnlineToken="[^"]*"' "$PREFS" | cut -d'"' -f2)
[ -n "$TOKEN" ] || { echo "Plex is not signed in yet: open http://<pi-ip>:32400/web first."; exit 1; }

SETTINGS=(
  # Never re-encode video: a file the player can't read is refused, not converted.
  "TranscoderCanOnlyRemuxVideo=1"
  "TranscodeCountLimit=1"
  "TranscoderQuality=1"                  # if audio must be converted: prefer speed
  "TranscoderTempDirectory=/transcode"   # RAM (tmpfs in docker-compose.yml)
  # No heavy background analysis: it hammers the CPU and the SD card.
  "GenerateBIFBehavior=never"            # video preview thumbnails
  "GenerateChapterThumbBehavior=never"
  "LoudnessAnalysisBehavior=never"
  "GenerateAdMarkerBehavior=never"
  "ButlerTaskDeepMediaAnalysis=0"
  "ScannerLowPriority=1"
  # Fewer writes, faster menus.
  "logDebug=0"
  "DatabaseCacheSize=256"                # MB, applied on next Plex restart
  "DlnaEnabled=0"
)

QUERY=$(IFS='&'; echo "${SETTINGS[*]}" | sed 's|/|%2F|g')
code=$(curl -s -o /dev/null -w '%{http_code}' -X PUT "http://localhost:32400/:/prefs?${QUERY}&X-Plex-Token=${TOKEN}")
[ "$code" = "200" ] && echo "Plex settings applied" || { echo "Plex API returned $code"; exit 1; }
