#!/bin/sh
# Installs sfos-nfc-wifi. Run as root (devel-su) in this directory.
set -e
cd "$(dirname "$0")"
install -D -m 644 files/NfcWifiHandler.qml /usr/share/sfos-nfc-wifi/NfcWifiHandler.qml
install -D -m 644 files/NfcWifiDialog.qml /usr/share/sfos-nfc-wifi/NfcWifiDialog.qml
install -D -m 644 files/sfos-nfc-wifi-dbus.conf /etc/dbus-1/system.d/sfos-nfc-wifi.conf
install -D -m 644 files/sfos-nfc-wifi-handler.conf /etc/nfcd/ndef-handlers/sfos-nfc-wifi.conf
install -D -m 644 patch/patch.json /usr/share/patchmanager/patches/nfc-wifi/patch.json
install -D -m 644 patch/unified_diff.patch /usr/share/patchmanager/patches/nfc-wifi/unified_diff.patch
gdbus call --system -d org.freedesktop.DBus -o /org/freedesktop/DBus -m org.freedesktop.DBus.ReloadConfig >/dev/null
systemctl restart nfcd
systemctl restart dbus-org.SfietKonstantin.patchmanager.service
echo "Installed. Enable \"NFC: join Wi-Fi from a tag\" in Settings → Patchmanager."
