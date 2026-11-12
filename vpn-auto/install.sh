#!/bin/sh
# Run as root on the phone from the directory with the files.
set -e
install -m 755 vpn-auto /usr/bin/vpn-auto
install -m 755 vpn-auto-ctl /usr/bin/vpn-auto-ctl
install -m 644 vpn-auto.privileges /usr/share/mapplauncherd/privileges.d/vpn-auto.privileges
install -m 644 vpn-auto.service /usr/lib/systemd/user/vpn-auto.service
mkdir -p /usr/lib/systemd/user/post-user-session.target.wants
ln -sf ../vpn-auto.service /usr/lib/systemd/user/post-user-session.target.wants/vpn-auto.service
install -m 644 vpn_auto.json /usr/share/jolla-settings/entries/vpn_auto.json
mkdir -p /usr/share/jolla-settings/pages/vpn_auto
install -m 644 VpnAutoPage.qml /usr/share/jolla-settings/pages/vpn_auto/VpnAutoPage.qml
install -m 644 translations/sfos-vpn-auto-fi.qm translations/sfos-vpn-auto_eng_en.qm /usr/share/translations/
echo OK  # then as the user: systemctl --user daemon-reload && systemctl --user start vpn-auto
