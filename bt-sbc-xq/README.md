# SBC XQ for Bluetooth headphones

Sailfish OS connects Bluetooth headphones with plain SBC every time. This user service switches each
connection to SBC XQ, a higher-bitrate SBC (552 kbit/s instead of about 330), and a top menu switch
"SBC XQ" turns the service on and off.

On Sailfish OS 5.2, PulseAudio offers headphones only SBC and SBC XQ (no AAC, aptX or LDAC), so XQ
is the best quality it has. XQ is used only when the headphones offer it (PulseAudio lists it for the
headphones); otherwise nothing is switched.

- **On every connection:** `bt-sbc-xq.service` (started with the session) follows PulseAudio and
  switches newly connected headphones from SBC to XQ while they are in the music profile (A2DP).
  A codec already other than plain SBC is left alone.
- **Playback goes on:** a codec switch moves playing streams to PulseAudio's null sink; they are
  moved back to the headphones.
- **Switch off:** the service is stopped and masked, so it also stays off after a reboot, and the
  connected headphones are switched back to plain SBC. On again: unmasked, started, switched to XQ.
- **Bitrate:** 552 kbit/s by default. If the sound cuts out more than with SBC, a lower one may help:
  `dconf write /apps/bt-sbc-xq/codec "'sbc_xq_512'"` (or `sbc_xq_453`), then turn the switch off and on.

Add the switch to the top menu in Settings → Look and feel → Top menu. To check the codec in use:
`pactl send-message /card/bluez_card.<address>/bluez get-codec`.

## Files

- `bt-sbc-xq`: the script (no argument: the service; `off`: back to plain SBC)
- `bt-sbc-xq.service`: the user service
- `bt_sbc_xq.json`, `EnableSwitch.qml`: the top menu switch. The switch is adapted from the Inari Blue
  switch of Sailfish OS (Jolla Mobile Ltd, BSD-3-Clause, notice in the file).

## Installing

As root (`devel-su`), in a directory with these files:

```sh
sh install.sh
```

Then as the user: `systemctl --user daemon-reload && systemctl --user start bt-sbc-xq`.

Tested on a Jolla phone with Sailfish OS 5.2.0.22 and Sennheiser MOMENTUM 4 headphones.
