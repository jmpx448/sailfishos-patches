#!/bin/sh
# Run as root on the phone from the directory with the files.
set -e
install -m 755 dnd-schedule /usr/bin/dnd-schedule
install -m 755 dnd-schedule-bt /usr/bin/dnd-schedule-bt
install -m 644 dnd-schedule.privileges /usr/share/mapplauncherd/privileges.d/dnd-schedule.privileges
install -m 644 dnd-schedule-sync.service /usr/lib/systemd/user/dnd-schedule-sync.service
mkdir -p /usr/lib/systemd/user/post-user-session.target.wants
ln -sf ../dnd-schedule-sync.service /usr/lib/systemd/user/post-user-session.target.wants/dnd-schedule-sync.service
install -m 644 dnd-schedule-led.service /usr/lib/systemd/user/dnd-schedule-led.service
ln -sf ../dnd-schedule-led.service /usr/lib/systemd/user/post-user-session.target.wants/dnd-schedule-led.service
install -m 644 dnd_schedule.json /usr/share/jolla-settings/entries/dnd_schedule.json
mkdir -p /usr/share/jolla-settings/pages/dnd_schedule
install -m 644 DndSchedulePage.qml /usr/share/jolla-settings/pages/dnd_schedule/DndSchedulePage.qml
install -m 644 translations/sfos-dnd-schedule-fi.qm translations/sfos-dnd-schedule_eng_en.qm /usr/share/translations/
echo OK  # then as the user: systemctl --user daemon-reload
