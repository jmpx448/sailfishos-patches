#!/bin/bash
# Builds noarch RPMs of the patches and tools into ../dist/ (not in git).
#   rpm/build-rpms.sh            all
#   rpm/build-rpms.sh topmenu-clock tailscale-toggle    only these
# Needs rpmbuild. The payload is xz: Sailfish OS 5.2 has rpm 4.16, which does not read zstd.
# Patch packages: sfos-patch-<name>, files in /usr/share/patchmanager/patches/<name>/,
# Requires patchmanager; removing the package unapplies the patch first.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DIST="$ROOT/dist"
TOOLS_VERSION=1.0.0
NFC_WIFI_VERSION=1.1.0
mkdir -p "$DIST"

build() { # spec-file
    rpmbuild -bb --nodeps "$1" \
        --define "_rpmdir $DIST" --define "_builddir $DIST/build" \
        --define "_buildrootdir $DIST/buildroot" --define "_srcrpmdir $DIST" \
        --define "_binary_payload w9.xzdio" --define "_source_payload w9.xzdio" \
        --define "src $ROOT" >/dev/null
}

patch_spec() { # name
    local d="$ROOT/$1" j
    j="$d/patch.json"
    python3 -I - "$j" <<'PY'
import json, sys, textwrap
p = json.load(open(sys.argv[1]))
desc = "\n".join(textwrap.wrap(p["description"], 76))
print(f"""Name:       sfos-patch-{p['name']}
Version:    {p['version']}
Release:    1
Summary:    Patchmanager patch: {p['display_name']}
License:    MIT
URL:        https://github.com/jmpx448/sailfishos-patches
BuildArch:  noarch
Requires:   patchmanager

%description
{desc}

Compatible with Sailfish OS {", ".join(p["compatible"])}. Enable it in
Settings > Patchmanager after installing.

%install
install -d %{{buildroot}}/usr/share/patchmanager/patches/{p['name']}
install -m 644 %{{src}}/{p['name']}/patch.json %{{src}}/{p['name']}/unified_diff.patch \\
    %{{buildroot}}/usr/share/patchmanager/patches/{p['name']}/

%preun
# Removal (not upgrade): unapply first, so the patched files are restored.
if [ "$1" -eq 0 ] && [ -x /usr/sbin/patchmanager ]; then
    /usr/sbin/patchmanager -u {p['name']} || true
fi

%files
%dir /usr/share/patchmanager/patches/{p['name']}
/usr/share/patchmanager/patches/{p['name']}/patch.json
/usr/share/patchmanager/patches/{p['name']}/unified_diff.patch
""")
PY
}

tool_spec() { # name
    case "$1" in
    tailscale-toggle) cat <<EOF2
Name:       sfos-tailscale-toggle
Version:    $TOOLS_VERSION
Release:    1
Summary:    Tailscale on/off page and top menu switch for Sailfish OS Settings
License:    MIT
URL:        https://github.com/jmpx448/sailfishos-patches
BuildArch:  noarch
Requires:   dconf

%description
A Settings > Connectivity page and a top menu switch that turn Tailscale on
and off; the switch is highlighted while connected. Needs tailscale and
tailscaled in /usr/local/bin, brought up once with --operator=<user>
(see README). Afterwards, as the user: systemctl --user daemon-reload &&
systemctl --user start tailscale-toggle-watch

%install
S=%{src}/tailscale-toggle
install -D -m 755 \$S/tailscale-toggle %{buildroot}/usr/bin/tailscale-toggle
for a in on off status watch; do
    install -D -m 644 \$S/tailscale-toggle-\$a.service %{buildroot}/usr/lib/systemd/user/tailscale-toggle-\$a.service
done
install -d %{buildroot}/usr/lib/systemd/user/post-user-session.target.wants
ln -s ../tailscale-toggle-watch.service %{buildroot}/usr/lib/systemd/user/post-user-session.target.wants/tailscale-toggle-watch.service
install -D -m 644 \$S/tailscale_toggle.json %{buildroot}/usr/share/jolla-settings/entries/tailscale_toggle.json
install -D -m 644 \$S/tailscale_toggle_switch.json %{buildroot}/usr/share/jolla-settings/entries/tailscale_toggle_switch.json
install -D -m 644 \$S/TailscalePage.qml %{buildroot}/usr/share/jolla-settings/pages/tailscale_toggle/TailscalePage.qml
install -D -m 644 \$S/EnableSwitch.qml %{buildroot}/usr/share/jolla-settings/pages/tailscale_toggle/EnableSwitch.qml

%files
/usr/bin/tailscale-toggle
/usr/lib/systemd/user/tailscale-toggle-*.service
/usr/lib/systemd/user/post-user-session.target.wants/tailscale-toggle-watch.service
/usr/share/jolla-settings/entries/tailscale_toggle.json
/usr/share/jolla-settings/entries/tailscale_toggle_switch.json
%dir /usr/share/jolla-settings/pages/tailscale_toggle
/usr/share/jolla-settings/pages/tailscale_toggle/*.qml
EOF2
    ;;
    dnd-schedule) cat <<EOF2
Name:       sfos-dnd-schedule
Version:    $TOOLS_VERSION
Release:    1
Summary:    Do not disturb schedule for Sailfish OS Settings
License:    MIT
URL:        https://github.com/jmpx448/sailfishos-patches
BuildArch:  noarch
Requires:   dconf

%description
Turns do not disturb on and off on a schedule (days, start and end) from a
Settings > Look and feel page, with timed events that also wake a sleeping
phone. Optionally keeps the Inari Blue LED and an Amazfish watch quiet
meanwhile, and turns Bluetooth off. Afterwards, as the user: systemctl --user daemon-reload

%install
S=%{src}/dnd-schedule
install -D -m 755 \$S/dnd-schedule %{buildroot}/usr/bin/dnd-schedule
install -D -m 755 \$S/dnd-schedule-bt %{buildroot}/usr/bin/dnd-schedule-bt
install -D -m 644 \$S/dnd-schedule.privileges %{buildroot}/usr/share/mapplauncherd/privileges.d/dnd-schedule.privileges
install -D -m 644 \$S/dnd-schedule-sync.service %{buildroot}/usr/lib/systemd/user/dnd-schedule-sync.service
install -D -m 644 \$S/dnd-schedule-led.service %{buildroot}/usr/lib/systemd/user/dnd-schedule-led.service
install -d %{buildroot}/usr/lib/systemd/user/post-user-session.target.wants
ln -s ../dnd-schedule-sync.service %{buildroot}/usr/lib/systemd/user/post-user-session.target.wants/dnd-schedule-sync.service
ln -s ../dnd-schedule-led.service %{buildroot}/usr/lib/systemd/user/post-user-session.target.wants/dnd-schedule-led.service
install -D -m 644 \$S/dnd_schedule.json %{buildroot}/usr/share/jolla-settings/entries/dnd_schedule.json
install -D -m 644 \$S/DndSchedulePage.qml %{buildroot}/usr/share/jolla-settings/pages/dnd_schedule/DndSchedulePage.qml
install -D -m 644 \$S/translations/sfos-dnd-schedule-fi.qm %{buildroot}/usr/share/translations/sfos-dnd-schedule-fi.qm
install -D -m 644 \$S/translations/sfos-dnd-schedule_eng_en.qm %{buildroot}/usr/share/translations/sfos-dnd-schedule_eng_en.qm

%files
/usr/bin/dnd-schedule
/usr/bin/dnd-schedule-bt
/usr/share/mapplauncherd/privileges.d/dnd-schedule.privileges
/usr/lib/systemd/user/dnd-schedule-*.service
/usr/lib/systemd/user/post-user-session.target.wants/dnd-schedule-*.service
/usr/share/jolla-settings/entries/dnd_schedule.json
%dir /usr/share/jolla-settings/pages/dnd_schedule
/usr/share/jolla-settings/pages/dnd_schedule/DndSchedulePage.qml
/usr/share/translations/sfos-dnd-schedule-fi.qm
/usr/share/translations/sfos-dnd-schedule_eng_en.qm
EOF2
    ;;
    nfc-wifi) cat <<EOF2
Name:       sfos-nfc-wifi
Version:    $NFC_WIFI_VERSION
Release:    1
Summary:    Join a Wi-Fi network from an NFC tag or QR code, after asking
License:    MIT
URL:        https://github.com/jmpx448/sailfishos-patches
BuildArch:  noarch
Requires:   patchmanager
Requires:   nfcd

%description
Touching an NFC tag with a Wi-Fi network (Wi-Fi Simple Configuration record),
or reading a Wi-Fi QR code with the Camera, asks whether to connect and adds
the network. A handler in the home screen, loaded by the included Patchmanager
patch "Wi-Fi from an NFC tag or QR code", which also adds a Connect to Wi-Fi
button to the Camera's QR code page: enable it in Settings > Patchmanager
after installing.

%install
S=%{src}/nfc-wifi
install -D -m 644 \$S/files/NfcWifiHandler.qml %{buildroot}/usr/share/sfos-nfc-wifi/NfcWifiHandler.qml
install -D -m 644 \$S/files/NfcWifiDialog.qml %{buildroot}/usr/share/sfos-nfc-wifi/NfcWifiDialog.qml
install -D -m 644 \$S/files/sfos-nfc-wifi-dbus.conf %{buildroot}/etc/dbus-1/system.d/sfos-nfc-wifi.conf
install -D -m 644 \$S/files/sfos-nfc-wifi-handler.conf %{buildroot}/etc/nfcd/ndef-handlers/sfos-nfc-wifi.conf
install -D -m 644 \$S/patch/patch.json %{buildroot}/usr/share/patchmanager/patches/nfc-wifi/patch.json
install -D -m 644 \$S/patch/unified_diff.patch %{buildroot}/usr/share/patchmanager/patches/nfc-wifi/unified_diff.patch

%post
gdbus call --system -d org.freedesktop.DBus -o /org/freedesktop/DBus -m org.freedesktop.DBus.ReloadConfig >/dev/null 2>&1 || true
systemctl try-restart nfcd >/dev/null 2>&1 || true

%preun
if [ "\$1" -eq 0 ] && [ -x /usr/sbin/patchmanager ]; then
    /usr/sbin/patchmanager -u nfc-wifi || true
fi

%postun
if [ "\$1" -eq 0 ]; then
    gdbus call --system -d org.freedesktop.DBus -o /org/freedesktop/DBus -m org.freedesktop.DBus.ReloadConfig >/dev/null 2>&1 || true
    systemctl try-restart nfcd >/dev/null 2>&1 || true
fi

%files
%dir /usr/share/sfos-nfc-wifi
/usr/share/sfos-nfc-wifi/*.qml
%config /etc/dbus-1/system.d/sfos-nfc-wifi.conf
%config /etc/nfcd/ndef-handlers/sfos-nfc-wifi.conf
%dir /usr/share/patchmanager/patches/nfc-wifi
/usr/share/patchmanager/patches/nfc-wifi/patch.json
/usr/share/patchmanager/patches/nfc-wifi/unified_diff.patch
EOF2
    ;;
    *) echo "unknown: $1" >&2; return 1 ;;
    esac
}

ITEMS=("$@")
if [ ${#ITEMS[@]} -eq 0 ]; then
    for d in "$ROOT"/*/; do
        n=$(basename "$d")
        [ -f "$d/patch.json" ] && [ -f "$d/unified_diff.patch" ] && ITEMS+=("$n")
    done
    ITEMS+=(tailscale-toggle dnd-schedule nfc-wifi)
fi
SPECS=$(mktemp -d)
trap 'rm -rf "$SPECS" "$DIST/build" "$DIST/buildroot"' EXIT
for n in "${ITEMS[@]}"; do
    if [ -f "$ROOT/$n/patch.json" ]; then patch_spec "$n" > "$SPECS/$n.spec"
    else tool_spec "$n" > "$SPECS/$n.spec"; fi
    build "$SPECS/$n.spec"
done
ls -1 "$DIST"/noarch/*.rpm
