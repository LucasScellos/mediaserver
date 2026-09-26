#!/usr/bin/env bash
# One screen health check: temperature, power, disks, containers, torrents.
cd "$(dirname "$0")/.."
DATA_DIR=$(grep -E '^DATA_DIR=' .env 2>/dev/null | cut -d= -f2- || true)
DATA_DIR=${DATA_DIR:-./downloads}
TR_USER=$(grep -E '^TRANSMISSION_USER=' .env 2>/dev/null | cut -d= -f2-)
TR_PASS=$(grep -E '^TRANSMISSION_PASS=' .env 2>/dev/null | cut -d= -f2-)

echo "== System"
uptime -p; cat /proc/loadavg | cut -d' ' -f1-3 | sed 's/^/load: /'
vcgencmd measure_temp
t=$(vcgencmd get_throttled | cut -d= -f2)
if [ "$t" = "0x0" ]; then echo "power: OK"; else echo "power: PROBLEM ($t) - weak power supply or overheating"; fi
systemctl is-active --quiet argononed && echo "fan: argononed running" || echo "fan: argononed NOT running"
free -h | awk '/Mem/ {print "ram: " $3 " used / " $2}'

echo; echo "== Disks"
df -h / "$DATA_DIR" | awk 'NR==1 || !seen[$1]++'

echo; echo "== Containers"
docker ps -a --format '{{.Names}}: {{.Status}}'

echo; echo "== Torrents"
docker exec transmission transmission-remote -n "$TR_USER:$TR_PASS" -l 2>/dev/null || echo "transmission not reachable"
