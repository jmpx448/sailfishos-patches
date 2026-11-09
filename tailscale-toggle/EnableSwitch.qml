import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import Nemo.DBus 2.0
import com.jolla.settings 1.0

// Top menu switch for Tailscale: highlighted while connected. The state comes from dconf,
// kept current by tailscale-toggle-watch.service and by the on/off units themselves.
SettingsToggle {
    id: root

    property bool waiting: false

    name: "Tailscale"
    icon.source: "image://theme/icon-m-vpn"
    checked: stateConfig.value === "Running"
    busy: waiting || stateConfig.value === "Starting"
    onToggled: {
        waiting = true
        systemd.typedCall("StartUnit",
                          [{ "type": "s", "value": "tailscale-toggle-" + (checked ? "off" : "on") + ".service" },
                           { "type": "s", "value": "replace" }])
        doneTimer.restart()
    }

    ConfigurationValue {
        id: stateConfig
        key: "/apps/tailscale-toggle/state"
        defaultValue: ""
        onValueChanged: root.waiting = false
    }

    // Should the state not change (the command failed): stop showing busy.
    Timer {
        id: doneTimer
        interval: 35000
        onTriggered: root.waiting = false
    }

    DBusInterface {
        id: systemd
        bus: DBus.SessionBus
        service: "org.freedesktop.systemd1"
        iface: "org.freedesktop.systemd1.Manager"
        path: "/org/freedesktop/systemd1"
    }
}
