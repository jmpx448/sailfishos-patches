# Wi-Fi from an NFC tag or QR code

Join a Wi-Fi network shared the way friends and cafés usually share it:

- **NFC tag:** touch a tag that holds a Wi-Fi network (a Wi-Fi Simple Configuration record,
  `application/vnd.wfa.wsc`, the format Android and iPhone use for network tags).
- **QR code:** read a Wi-Fi QR code (`WIFI:S:…;T:WPA;P:…;;`) with the Camera (QR code detection
  on in the Camera settings) and open it. The QR code page shows the code with the password
  hidden (••••••) and a **Connect to Wi-Fi** button. The Camera's own Copy button still copies
  the whole code, password included.

Either way the phone asks whether to connect, showing the network name and type, not the
password. **Connect** adds the network to the saved Wi-Fi networks (auto-connect on) and
connects; after a QR code, the QR code page closes too. **Cancel** or a tap outside the dialog
does nothing. The texts are in Finnish when the phone language is Finnish, otherwise in English.

Without this, Sailfish OS reads such a tag (the phone vibrates) but has no handler for it, and the
Camera shows a Wi-Fi QR code only as text, password included.

The confirmation is there on purpose: without it, anyone could make the phone join their network
by holding a tag to it.

Supported: open networks and WPA/WPA2-Personal (the password is in the tag or code), also
hidden networks from QR codes. Other types (WEP, enterprise) are ignored. The password is kept
only in memory and never logged.

## How it works

- `sfos-nfc-wifi-handler.conf` (in `/etc/nfcd/ndef-handlers/`) tells nfcd to pass Wi-Fi records
  to `org.jmpx448.nfcwifi` on the system bus.
- `NfcWifiHandler.qml` runs inside the home screen (lipstick), owns that D-Bus name, reads the
  network name, type and password, and adds the network with connman.
- The Camera runs in a sandbox that can't change network settings or call the handler, but it
  can write dconf. Its QR code page writes the code to `/apps/sfos-nfc-wifi/qr-request`; the
  handler clears the key at once and shows the dialog. After **Connect** it writes
  `/apps/sfos-nfc-wifi/qr-result`, and the QR code page closes.
- `NfcWifiDialog.qml` is the confirmation dialog.
- `sfos-nfc-wifi-dbus.conf` (in `/etc/dbus-1/system.d/`) lets lipstick own the name and nfcd call it.
- The Patchmanager patch in `patch/` adds a `Loader` for the handler to lipstick's
  `compositor.qml`, and the button to the Camera's `QrPage.qml`. If the handler files are
  missing, the home screen just logs a warning.

## Installing

As root (`devel-su`), in this directory:

```sh
sh install.sh
```

Then enable **Wi-Fi from an NFC tag or QR code** in Settings → Patchmanager and let it restart
the home screen and the Camera.

To remove: disable the patch in Patchmanager, then delete `/usr/share/sfos-nfc-wifi/`,
`/etc/nfcd/ndef-handlers/sfos-nfc-wifi.conf`, `/etc/dbus-1/system.d/sfos-nfc-wifi.conf` and
`/usr/share/patchmanager/patches/nfc-wifi/`.
