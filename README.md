# Sailfish OS patches

Small user interface patches for Sailfish OS, applied with
[Patchmanager](https://github.com/sailfishos-patches/patchmanager) 3.x.
Written for and tested on a Jolla phone with Sailfish OS 5.2.0.22.

## Patches

| Patch | Version | Sailfish OS | Description |
|---|---|---|---|
| [Calendar events: show end time](calendar-widget-end-time/) | 1.1.0 | 5.2.0.20, 5.2.0.22 | Shows the end time next to the start time of calendar events in the Events view (e.g. 1:30 - 8:30), and keeps timed events visible until they end instead of hiding them 15 minutes after the start. All-day events are unchanged. |
| [Calendar events: week number](calendar-widget-week-number/) | 1.2.0 | 5.2.0.22 | Shows the current ISO week number under the calendar icon of the Events view (wk 46), and names the week in the day headings only when the list continues into a later week, e.g. Monday (wk 47). The abbreviation is vko (viikko) when the language is Finnish. |
| [Top menu: clock above the lock](topmenu-clock/) | 1.0.1 | 5.2.0.22 | Shows the time above the lock icon in the top menu. |
| [Top menu: adaptive brightness button](topmenu-auto-brightness/) | 1.0.2 | 5.2.0.22 | Adds a round A button next to the top menu brightness slider to toggle adaptive brightness. |
| [Lock screen: confirm code without OK](lockscreen-auto-confirm/) | 1.0.0 | 5.2.0.22 | Checks the lock code as soon as it is as long as the stored code, without pressing OK. A wrong code of that length counts as a failed attempt. |
| [Keyboard: clipboard history](keyboard-clipboard-history/) | 1.0.0 | 5.2.0.22 | Remembers the last 10 copied texts. A history button next to the keyboard's clipboard button shows them; tap one to paste it. Kept only in memory (cleared when the keyboard restarts) and emptied with Clear clipboard. |
| [Do not disturb: grey screen](dnd-grayscale/) | 1.0.0 | 5.2.0.22 | Shows the whole screen in greyscale while Do not disturb is on, like the bedtime mode on Android phones. Follows the Do not disturb switch and schedules; turn it off without unapplying with `dconf write /desktop/lipstick-jolla-home/dnd_grayscale false`. |
| [Notifications: hide Android group summaries](android-group-summary-hide/) | 1.0.1 | 5.2.0.22 | Hides the extra "New messages" summary notification Android apps (Proton Mail) post above their real notifications. Hidden, not closed, so the real notifications stay. |

## Other

| Tool | Description |
|---|---|
| [Tailscale on/off in Settings](tailscale-toggle/) | A Settings page and a top menu switch to turn Tailscale on and off; the switch is highlighted while connected. Installed with its own `install.sh`, not with Patchmanager. |
| [Do not disturb schedule](dnd-schedule/) | Turns do not disturb on and off on a schedule (days, start and end), from a Settings page. Optionally keeps the Inari Blue LED and an Amazfish watch quiet meanwhile. Installed with its own `install.sh`. |
| [Wi-Fi from an NFC tag or QR code](nfc-wifi/) | Touching an NFC tag with a Wi-Fi network, or reading a Wi-Fi QR code with the Camera, asks whether to connect and adds the network. The Camera's QR page hides the password. Handler in the home screen plus a small Patchmanager patch; installed with its own `install.sh`. |

## Installing

### RPM packages

Each patch and tool is also an RPM on the [Releases](https://github.com/jmpx448/sailfishos-patches/releases)
page (noarch). Install as root (`devel-su`):

```sh
rpm -Uvh sfos-patch-topmenu-clock-1.0.1-1.noarch.rpm
```

- **Patches** (`sfos-patch-<name>`) need Patchmanager. After installing, enable the patch in
  Settings → Patchmanager. Removing the package (`rpm -e`) unapplies the patch first.
- **Tools** (`sfos-tailscale-toggle`, `sfos-dnd-schedule`): afterwards, as the user,
  `systemctl --user daemon-reload` (see each tool's README for what else to start).

`rpm/build-rpms.sh` builds them into `dist/` (needs `rpmbuild`; xz payload, as the phone's rpm 4.16
does not read zstd).

### By hand

These are not in the Patchmanager web catalog. Install a patch by hand as root (`devel-su`):

```sh
mkdir -p /usr/share/patchmanager/patches/<patch-name>
cp patch.json unified_diff.patch /usr/share/patchmanager/patches/<patch-name>/
systemctl restart dbus-org.SfietKonstantin.patchmanager.service
```

Then enable it in Settings → Patchmanager and restart the affected service (Patchmanager offers this).
You can test a patch first with `cd / && patch -p1 --dry-run < unified_diff.patch`.

## Notes

- **Check after every Sailfish OS update.** The `compatible` list only names versions the patch was tested on.
- **Lock screen: confirm code without OK** changes the device lock view. Test it with SSH access open,
  so you can unapply it if something goes wrong. A full-length wrong code counts as a failed attempt.
- **Keyboard: clipboard history** keeps the last 10 texts in memory only. After enabling, restart the keyboard:
  `systemctl --user restart maliit-server`.
- **Hide Android group summaries** recognises summaries by package and text; the list is in `_isAndroidGroupSummary`.

## License

MIT, see [LICENSE](LICENSE). The diffs contain context lines from Sailfish OS files, which belong to their owners.
