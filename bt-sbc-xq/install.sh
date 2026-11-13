#!/bin/sh
# Run as root on the phone from the directory with the files.
set -e
install -m 755 bt-sbc-xq /usr/bin/bt-sbc-xq
install -m 644 bt-sbc-xq.service /usr/lib/systemd/user/bt-sbc-xq.service
mkdir -p /usr/lib/systemd/user/post-user-session.target.wants
ln -sf ../bt-sbc-xq.service /usr/lib/systemd/user/post-user-session.target.wants/bt-sbc-xq.service
install -m 644 bt_sbc_xq.json /usr/share/jolla-settings/entries/bt_sbc_xq.json
mkdir -p /usr/share/jolla-settings/pages/bt_sbc_xq
install -m 644 EnableSwitch.qml /usr/share/jolla-settings/pages/bt_sbc_xq/EnableSwitch.qml
echo OK  # then as the user: systemctl --user daemon-reload && systemctl --user start bt-sbc-xq
