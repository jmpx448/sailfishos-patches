# Automatic VPN

A page in Settings → Connectivity ("Automatic VPN", in Finnish "Automaattinen VPN") that keeps the
VPN off on trusted Wi-Fi networks, such as the home network, and on everywhere else: on mobile data
and on other Wi-Fi networks. The texts are in Finnish when the phone language is Finnish, otherwise
in English.

- **Trusted networks:** connect to the network and tap *Add as trusted*. A network is recognised by
  its name (SSID) and the hardware address of its router, so another network with the same name is
  not trusted. Long press a trusted network to delete it.
- **Same as the VPN switch:** the VPN is turned on and off by its automatic connection, as the VPN
  switch in Settings and the top menu does. connman then connects or disconnects it, and reconnects
  it when the network comes back. The switch always shows the state.
- **By hand wins:** the VPN is only turned on or off when the network changes (or when the setting
  is turned on, or the current network is added or deleted). Turned on or off by hand with the
  switch, it stays so until the next change.
- **Several VPNs:** the one to use is chosen on the page (the first one by default).
- **A gap when the network changes:** traffic goes without the VPN for a few seconds, until it has
  connected. There is no firewall rule against that.

Settings are in dconf under `/apps/vpn-auto/`. `vpn-auto status` prints the state (without network
names); events are logged to `/tmp/vpn-auto.log`.

## Files

- `vpn-auto`: the service (`run`) and `status`
- `vpn-auto.service`: starts it at the start of the session
- `vpn-auto-ctl`, `vpn-auto.privileges`: turns the VPN on or off. connman allows that only for the
  privileged group, which `invoker` gives to the programs listed in mapplauncherd's `privileges.d`.
  connman-vpn's own Connect and Disconnect are refused for everyone but connman itself.
- `vpn_auto.json`, `VpnAutoPage.qml`: the Settings entry and page
- `translations/`: the Settings entry's title (`.ts` sources; the `.qm` files are built from them
  with `lrelease-qt5 -idbased`)

## Installing

As root (`devel-su`), in a directory with these files:

```sh
sh install.sh
```

Then as the user: `systemctl --user daemon-reload && systemctl --user start vpn-auto`.

Tested on a Jolla phone with Sailfish OS 5.2.0.22 and a WireGuard VPN.
