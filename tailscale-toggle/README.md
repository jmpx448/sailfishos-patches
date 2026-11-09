# Tailscale on/off in Settings

A page in Settings → Connectivity with a switch that turns [Tailscale](https://tailscale.com/) on and off,
shows its state (connected, off, connecting) and the device's Tailscale address. The texts are in Finnish.

Sailfish OS has no official Tailscale client. This assumes the static arm64 build from
[pkgs.tailscale.com](https://pkgs.tailscale.com/stable/#static) in `/usr/local/bin`, `tailscaled` running as a
system service, and that it was brought up once with your user as operator, so `tailscale up/down`
need no root:

```sh
tailscale up --accept-dns=false --hostname=jolla --operator=defaultuser
```

`tailscale-toggle on` repeats these flags (tailscale refuses to change settings without the non-default
ones), so edit them in the script if you used others.

## How it works

- `tailscale-toggle on|off|status` runs `tailscale up`/`down` as the user and writes the resulting
  state and address to dconf (`/apps/tailscale-toggle/state`, `/apps/tailscale-toggle/ip`).
- The page starts the user units `tailscale-toggle-{on,off,status}.service` over D-Bus and reads the
  state from dconf. It refreshes every 10 s while open.
- Off stays off across reboots (`tailscale down` is remembered by tailscaled). If you reach the phone
  over Tailscale, turning it off cuts that connection.

## Installing

As root (`devel-su`), in a directory with these files:

```sh
sh install.sh
```

Then as the user: `systemctl --user daemon-reload`. The page appears in Settings → Connectivity.

Tested on a Jolla phone with Sailfish OS 5.2.0.22 and Tailscale 1.104.2.
