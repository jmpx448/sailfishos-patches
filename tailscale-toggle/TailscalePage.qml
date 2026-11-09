import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import Nemo.DBus 2.0

// Tailscale on/off. The switch starts tailscale-toggle-on/off.service (user units, which run
// /usr/bin/tailscale-toggle); the script writes the resulting state to dconf, read here.
Page {
    id: page

    property bool busy: false
    readonly property string tsState: stateConfig.value
    readonly property bool running: tsState === "Running"

    function stateText() {
        if (busy) return "Odotetaan…"
        switch (tsState) {
        case "Running": return "Yhdistetty"
        case "Stopped": return "Pois päältä"
        case "Starting": return "Yhdistetään…"
        case "NeedsLogin": return "Vaatii kirjautumisen"
        case "NoState": return "Ei tilaa"
        case "": return "Haetaan tilaa…"
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
                text: "Päivitä tila"
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
                label: "Osoite"
                value: ipConfig.value
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                topPadding: Theme.paddingLarge
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
                text: "Kun Tailscale on pois päältä, puhelimeen ei saa etäyhteyttä Tailscalen kautta. "
                      + "Valinta säilyy uudelleenkäynnistyksen yli: laita Tailscale takaisin päälle täältä."
            }
        }
    }
}
