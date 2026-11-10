# NFC: join Wi-Fi from a tag

Touch an NFC tag that holds a Wi-Fi network (a Wi-Fi Simple Configuration record,
`application/vnd.wfa.wsc`, the format Android and iPhone use for network tags), and the phone
asks whether to connect to it. The dialog shows the network name and type, not the password.
**Connect** adds the network to the saved Wi-Fi networks (auto-connect on) and connects;
**Cancel** or a tap outside the dialog does nothing. The texts are in Finnish when the phone
language is Finnish, otherwise in English.

Without this, Sailfish OS reads such a tag (the phone vibrates) but has no handler for it.

The confirmation is there on purpose: without it, anyone could make the phone join their network
by holding a tag to it.

Supported: open networks and WPA/WPA2-Personal (the password is on the tag). Other types
(WEP, enterprise) are ignored. The password is kept only in memory; the log only says how many
bytes the tag had and whether it was usable.

## How it works

- `sfos-nfc-wifi-handler.conf` (in `/etc/nfcd/ndef-handlers/`) tells nfcd to pass these records
  to `org.jmpx448.nfcwifi` on the system bus.
- `NfcWifiHandler.qml` runs inside the home screen (lipstick), owns that D-Bus name, reads the
  network name, type and password from the record, and adds the network with connman.
- `NfcWifiDialog.qml` is the confirmation dialog.
- `sfos-nfc-wifi-dbus.conf` (in `/etc/dbus-1/system.d/`) lets lipstick own the name and nfcd call it.
- The Patchmanager patch in `patch/` adds one `Loader` to lipstick's `compositor.qml` that loads
  the handler. If the handler files are missing, the home screen just logs a warning.

## Installing

As root (`devel-su`), in this directory:

```sh
sh install.sh
```

Then enable **NFC: join Wi-Fi from a tag** in Settings → Patchmanager and let it restart the
home screen.

To remove: disable the patch in Patchmanager, then delete `/usr/share/sfos-nfc-wifi/`,
`/etc/nfcd/ndef-handlers/sfos-nfc-wifi.conf`, `/etc/dbus-1/system.d/sfos-nfc-wifi.conf` and
`/usr/share/patchmanager/patches/nfc-wifi/`.
