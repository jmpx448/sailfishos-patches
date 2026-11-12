import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import Nemo.DBus 2.0

// Tailscale on/off. The switch starts tailscale-toggle-on/off.service (user units, which run
// /usr/bin/tailscale-toggle); the script writes the resulting state to dconf, read here.
Page {
    id: page

    property bool busy: false
    readonly property bool finnish: Qt.locale().name.indexOf("fi") === 0
    readonly property string tsState: stateConfig.value
    readonly property bool running: tsState === "Running"

    function stateText() {
        if (busy) return finnish ? "Odotetaan…" : "Waiting…"
        switch (tsState) {
        case "Running": return finnish ? "Yhdistetty" : "Connected"
        case "Stopped": return finnish ? "Pois päältä" : "Off"
        case "Starting": return finnish ? "Yhdistetään…" : "Connecting…"
        case "NeedsLogin": return finnish ? "Vaatii kirjautumisen" : "Needs login"
        case "NoState": return finnish ? "Ei tilaa" : "No state"
        case "": return finnish ? "Haetaan tilaa…" : "Getting status…"
        default: return tsState
        }
    }

    function run(action) {
        busy = action !== "status"
        systemd.typedCall("StartUnit",
                          [{ "type": "s", "value": "tailscale-toggle-" + action + ".service" },
                           { "type": "s", "value": "replace" }])
        doneTimer.restart()
    }

    ConfigurationValue {
        id: stateConfig
        key: "/apps/tailscale-toggle/state"
        defaultValue: ""
        // The script writes the state once up/down has finished.
        onValueChanged: page.busy = false
    }
    ConfigurationValue {
        id: ipConfig
        key: "/apps/tailscale-toggle/ip"
        defaultValue: ""
    }

    DBusInterface {
        id: systemd
        bus: DBus.SessionBus
        service: "org.freedesktop.systemd1"
        iface: "org.freedesktop.systemd1.Manager"
        path: "/org/freedesktop/systemd1"
    }

    // Should the state not change (same as before, or the command failed): stop waiting.
    Timer {
        id: doneTimer
        interval: 35000
        onTriggered: { page.busy = false; page.run("status") }
    }
    // Refresh while the page is open: tailscale may change state on its own (network change).
    Timer {
        running: page.status === PageStatus.Active && !page.busy
        interval: 10000
        repeat: true
        onTriggered: page.run("status")
    }

    Component.onCompleted: run("status")

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem {
                text: page.finnish ? "Päivitä tila" : "Refresh status"
                onClicked: page.run("status")
            }
        }

        Column {
            id: column
            width: parent.width

            PageHeader { title: "Tailscale" }

            TextSwitch {
                text: "Tailscale"
                description: page.stateText()
                checked: page.running
                automaticCheck: false
                busy: page.busy
                enabled: !page.busy
                onClicked: page.run(page.running ? "off" : "on")
            }

            DetailItem {
                visible: page.running && ipConfig.value !== ""
                label: page.finnish ? "Osoite" : "Address"
                value: ipConfig.value
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                topPadding: Theme.paddingLarge
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
                text: page.finnish
                      ? "Kun Tailscale on pois päältä, puhelimeen ei saa etäyhteyttä Tailscalen kautta. "
                        + "Valinta säilyy uudelleenkäynnistyksen yli: laita Tailscale takaisin päälle täältä."
                      : "While Tailscale is off, the phone cannot be reached remotely through Tailscale. "
                        + "The choice is kept over a restart: turn Tailscale back on here."
            }
        }
    }
}
