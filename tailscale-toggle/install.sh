#!/bin/sh
# Run as root on the phone from the directory with the files.
set -e
install -m 755 tailscale-toggle /usr/bin/tailscale-toggle
for a in on off status; do
    install -m 644 tailscale-toggle-$a.service /usr/lib/systemd/user/tailscale-toggle-$a.service
done
install -m 644 tailscale_toggle.json /usr/share/jolla-settings/entries/tailscale_toggle.json
mkdir -p /usr/share/jolla-settings/pages/tailscale_toggle
install -m 644 TailscalePage.qml /usr/share/jolla-settings/pages/tailscale_toggle/TailscalePage.qml
echo OK  # then as the user: systemctl --user daemon-reload
