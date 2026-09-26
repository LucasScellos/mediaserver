#!/usr/bin/env bash
# Installs the Argon ONE fan + power button service (argononed) from Argon40.
# The official script ends with a full `apt-get upgrade` and an EEPROM rewrite;
# those lines are removed so the install doesn't restart everything behind your back.
set -euo pipefail
tmp=$(mktemp)
curl -fsSL https://download.argon40.com/argon1.sh -o "$tmp"
sed -i -e '/apt-get upgrade -y/d' -e '/sudo rpi-eeprom-update/d' -e '/sudo \$eepromconfigscript$/d' "$tmp"
bash "$tmp"
rm -f "$tmp"
systemctl is-active argononed && echo "Fan curve: /etc/argononed.conf (change with: argon-config)"
