# Do not disturb schedule

A page in Settings → Look and feel ("Do not disturb schedule", in Finnish "Älä häiritse -ajastus")
that turns do not disturb on and off on a schedule. The texts are in Finnish when the phone language
is Finnish, otherwise in English.

- **Schedules:** any number of rules, each with days of the week, a start and an end time. An end
  before the start runs over midnight. Add one by pulling the page down; tap to edit, long press
  to delete.
- **Timed events:** the start and end of each rule are scheduled with `timed`, which also wakes a
  sleeping phone. After a reboot, or if the phone was off at a start or end, the state is put right
  at the start of the session.
- **By hand wins:** the end of a rule only turns do not disturb off if the schedule turned it on.
  Turned off by hand during a rule, it stays off.
- **LED off (optional):** with [Inari Blue Notifier](https://github.com/RikudouSage/InariBlueNotifierDaemon),
  its daemon is stopped while do not disturb is on. Afterwards the LED shows, until the next unlock,
  the pattern of what came in meanwhile, using Inari's own notification filters and patterns.
- **Watch off (optional):** with [Amazfish](https://github.com/piggz/harbour-amazfish), its service
  is stopped while do not disturb is on, as the watch would otherwise still buzz. It is started
  again (and reconnected) afterwards.
- **Bluetooth off (optional):** Bluetooth is turned off while do not disturb is on, and back on
  afterwards if it was on before. The phone then neither keeps up the watch link nor scans for the
  watch, and sleeps much better. Turned on by hand meanwhile, it stays on.

Rules and settings are in dconf under `/apps/dnd-schedule/`. `dnd-schedule status` prints the
rules and the state.

## Files

- `dnd-schedule`: the script (`sync`, `start`, `end`, `led`, `status`)
- `dnd-schedule-sync.service`: reschedules at the start of the session and after a change on the page
- `dnd-schedule-led.service`: the LED, watch and Bluetooth part (`dnd-schedule led`)
- `dnd-schedule-bt`, `dnd-schedule.privileges`: turns Bluetooth on or off; connman allows that only
  for the privileged group, which `invoker` gives to the programs listed in mapplauncherd's
  `privileges.d`
- `dnd_schedule.json`, `DndSchedulePage.qml`: the Settings entry and page
- `translations/`: the Settings entry's title (`.ts` sources; the `.qm` files are built from them with
  `lrelease-qt5 -idbased`)

## Installing

As root (`devel-su`), in a directory with these files:

```sh
sh install.sh
```

Then as the user: `systemctl --user daemon-reload`.

Tested on a Jolla phone with Sailfish OS 5.2.0.22.
