#!/usr/bin/env bash
# One-shot system tuning for a Pi 4 running Plex + Transmission. Safe to run again.
# Usage: sudo ./scripts/tune-pi.sh
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo"; exit 1; }

step() { printf '\n==> %s\n' "$1"; }

step "Wi-Fi power saving off (it adds latency to SSH, the web UI and streams)"
mkdir -p /etc/NetworkManager/conf.d
printf '[connection]\nwifi.powersave = 2\n' > /etc/NetworkManager/conf.d/99-wifi-powersave-off.conf
/usr/sbin/iw dev wlan0 set power_save off 2>/dev/null || true

step "Smoother disk writes: flush small batches often instead of ~700 MB at once"
# With the default dirty_ratio=20 the kernel buffers up to ~20% of RAM, then
# freezes writers while a slow SD card flushes it: that is the periodic 'lag'.
cat > /etc/sysctl.d/99-mediaserver.conf <<'EOF'
vm.dirty_background_bytes = 16777216
vm.dirty_bytes = 67108864
vm.swappiness = 10
EOF
sysctl -q --system

step "Cap the systemd journal at 100 MB (it was ~790 MB on the SD card)"
mkdir -p /etc/systemd/journald.conf.d
printf '[Journal]\nSystemMaxUse=100M\n' > /etc/systemd/journald.conf.d/99-size.conf
systemctl restart systemd-journald
journalctl --vacuum-size=100M -q

step "Disable services this box does not use"
for svc in bluetooth ModemManager triggerhappy; do
  systemctl disable --now "$svc" 2>/dev/null && echo "disabled $svc" || true
done

step "Remove the daily 05:00 reboot (it cuts seeding and hid the real problem)"
if crontab -l 2>/dev/null | grep -q '/sbin/shutdown -r now'; then
  crontab -l | grep -v '/sbin/shutdown -r now' | crontab -
  echo "removed from root crontab"
else
  echo "not present"
fi

step "Timezone Europe/Paris"
timedatectl set-timezone Europe/Paris

step "Remove unused Docker images and networks (old sonarr/radarr/jellyfin/... ~4 GB)"
docker image prune -af
docker network prune -f

echo
echo "Done. Reboot once to apply everything cleanly: sudo reboot"
