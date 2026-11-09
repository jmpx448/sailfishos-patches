#!/bin/sh
# Run as root on the phone from the directory with the files.
set -e
install -m 755 tailscale-toggle /usr/bin/tailscale-toggle
for a in on off status watch; do
    install -m 644 tailscale-toggle-$a.service /usr/lib/systemd/user/tailscale-toggle-$a.service
done
mkdir -p /usr/lib/systemd/user/post-user-session.target.wants
ln -sf ../tailscale-toggle-watch.service /usr/lib/systemd/user/post-user-session.target.wants/tailscale-toggle-watch.service
install -m 644 tailscale_toggle.json /usr/share/jolla-settings/entries/tailscale_toggle.json
install -m 644 tailscale_toggle_switch.json /usr/share/jolla-settings/entries/tailscale_toggle_switch.json
mkdir -p /usr/share/jolla-settings/pages/tailscale_toggle
install -m 644 TailscalePage.qml /usr/share/jolla-settings/pages/tailscale_toggle/TailscalePage.qml
install -m 644 EnableSwitch.qml /usr/share/jolla-settings/pages/tailscale_toggle/EnableSwitch.qml
echo OK  # then as the user: systemctl --user daemon-reload && systemctl --user start tailscale-toggle-watch
