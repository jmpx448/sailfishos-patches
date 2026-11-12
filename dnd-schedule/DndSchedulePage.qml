import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import Nemo.DBus 2.0

// Do not disturb schedule. The rules are a JSON string in dconf; after a change
// dnd-schedule-sync.service turns them into timed events (/usr/bin/dnd-schedule).
Page {
    id: page

    property var rules: []
    readonly property bool finnish: Qt.locale().name.indexOf("fi") === 0
    readonly property var dayNames: finnish ? ["ma", "ti", "ke", "to", "pe", "la", "su"]
                                            : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    function pad(n) { return n < 10 ? "0" + n : "" + n }
    function timeText(m) { return Math.floor(m / 60) + (finnish ? "." : ":") + pad(m % 60) }

    function daysText(days) {
        var d = days.slice(0).sort()
        var s = d.join(",")
        if (s === "1,2,3,4,5,6,7") return finnish ? "Joka päivä" : "Every day"
        if (s === "1,2,3,4,5") return finnish ? "Arkipäivät" : "Weekdays"
        if (s === "6,7") return finnish ? "Viikonloppu" : "Weekend"
        // Runs of three or more days as a range: ma–to, la.
        var parts = []
        var i = 0
        while (i < d.length) {
            var j = i
            while (j + 1 < d.length && d[j + 1] === d[j] + 1) ++j
            if (j - i >= 2)
                parts.push(dayNames[d[i] - 1] + "–" + dayNames[d[j] - 1])
            else
                for (var k = i; k <= j; ++k) parts.push(dayNames[d[k] - 1])
            i = j + 1
        }
        return parts.join(", ")
    }

    function load() {
        var r = []
        try { r = JSON.parse(rulesConfig.value) } catch (e) { }
        rules = r
    }

    function save(r) {
        rules = r
        rulesConfig.value = JSON.stringify(r)
        syncTimer.restart()
    }

    function setRule(index, rule) {
        var r = rules.slice(0)
        if (index < 0) r.push(rule)
        else r[index] = rule
        save(r)
    }

    function removeRule(index) {
        var r = rules.slice(0)
        r.splice(index, 1)
        save(r)
    }

    ConfigurationValue {
        id: rulesConfig
        key: "/apps/dnd-schedule/rules"
        defaultValue: "[]"
        onValueChanged: page.load()
    }
    ConfigurationValue {
        id: enabledConfig
        key: "/apps/dnd-schedule/enabled"
        defaultValue: true
    }
    ConfigurationValue {
        id: ledOffConfig
        key: "/apps/dnd-schedule/led_off"
        defaultValue: true
    }
    ConfigurationValue {
        id: watchOffConfig
        key: "/apps/dnd-schedule/watch_off"
        defaultValue: false
    }
    ConfigurationValue {
        id: btOffConfig
        key: "/apps/dnd-schedule/bt_off"
        defaultValue: false
    }
    ConfigurationValue {
        id: dndConfig
        key: "/lipstick/do_not_disturb"
        defaultValue: false
    }

    // The dconf write reaches other processes a moment later; this also gathers quick edits.
    Timer {
        id: syncTimer
        interval: 800
        onTriggered: systemd.call("StartUnit", ["dnd-schedule-sync.service", "replace"])
    }

    DBusInterface {
        id: systemd
        bus: DBus.SessionBus
        service: "org.freedesktop.systemd1"
        iface: "org.freedesktop.systemd1.Manager"
        path: "/org/freedesktop/systemd1"
    }

    Component.onCompleted: load()

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem {
                text: page.finnish ? "Lisää aikataulu" : "Add schedule"
                onClicked: pageStack.push(ruleDialog, {
                    ruleIndex: -1, days: [1, 2, 3, 4, 5], start: 22 * 60, end: 7 * 60 })
            }
        }

        Column {
            id: column
            width: parent.width

            PageHeader { title: page.finnish ? "Älä häiritse -ajastus" : "Do not disturb schedule" }

            TextSwitch {
                text: page.finnish ? "Ajastus käytössä" : "Schedule enabled"
                description: page.finnish
                             ? "Älä häiritse -tila menee päälle ja pois aikataulujen mukaan. "
                               + "Jos kytket tilan käsin pois kesken aikataulun, se pysyy pois "
                               + "seuraavaan alkuun asti."
                             : "Do not disturb turns on and off according to the schedules. "
                               + "If you turn it off by hand during a schedule, it stays off "
                               + "until the next start."
                automaticCheck: false
                checked: !!enabledConfig.value
                onClicked: {
                    enabledConfig.value = !enabledConfig.value
                    syncTimer.restart()
                }
            }

            // dnd-schedule-led.service follows this key and do not disturb itself.
            TextSwitch {
                text: page.finnish ? "Merkkivalo pois" : "LED off"
                description: page.finnish
                             ? "Inari Bluen merkkivalo on sammuksissa aina, kun Älä häiritse -tila on päällä."
                             : "The Inari Blue LED stays off whenever Do not disturb is on."
                automaticCheck: false
                checked: !!ledOffConfig.value
                onClicked: ledOffConfig.value = !ledOffConfig.value
            }

            TextSwitch {
                text: page.finnish ? "Kello pois" : "Watch off"
                description: page.finnish
                             ? "Amazfish pysäytetään Älä häiritse -tilan ajaksi, joten kello ei saa "
                               + "ilmoituksia eikä puheluita eikä värise. Tilan aikana tulleet ilmoitukset "
                               + "eivät tule kelloon jälkikäteen, mutta ne ovat puhelimessa tallessa."
                             : "Amazfish is stopped while Do not disturb is on, so the watch gets no "
                               + "notifications or calls and does not vibrate. Notifications that come in "
                               + "meanwhile are not sent to the watch afterwards, but they are kept on the phone."
                automaticCheck: false
                checked: !!watchOffConfig.value
                onClicked: watchOffConfig.value = !watchOffConfig.value
            }

            TextSwitch {
                text: page.finnish ? "Bluetooth pois" : "Bluetooth off"
                description: page.finnish
                             ? "Bluetooth kytketään pois Älä häiritse -tilan ajaksi ja takaisin päälle, "
                               + "kun tila päättyy, jos se oli päällä. Puhelin ei silloin pidä yhteyttä "
                               + "kelloon eikä etsi sitä, joten akkua kuluu vähemmän. Kello ja "
                               + "Bluetooth-kuulokkeet eivät toimi tilan aikana. Jos kytket Bluetoothin "
                               + "käsin päälle kesken tilan, se pysyy päällä."
                             : "Bluetooth is turned off while Do not disturb is on, and back on when it "
                               + "ends if it was on. The phone then neither keeps up the link to the watch "
                               + "nor scans for it, so it uses less battery. The watch and Bluetooth "
                               + "headphones do not work meanwhile. If you turn Bluetooth on by hand "
                               + "during it, it stays on."
                automaticCheck: false
                checked: !!btOffConfig.value
                onClicked: btOffConfig.value = !btOffConfig.value
            }

            DetailItem {
                label: page.finnish ? "Älä häiritse nyt" : "Do not disturb now"
                value: dndConfig.value ? (page.finnish ? "Päällä" : "On") : (page.finnish ? "Pois" : "Off")
            }

            SectionHeader { text: page.finnish ? "Aikataulut" : "Schedules" }

            Repeater {
                model: page.rules.length

                ListItem {
                    id: item
                    property var rule: page.rules[index]
                    contentHeight: Theme.itemSizeMedium
                    opacity: rule.on && enabledConfig.value ? 1.0 : Theme.opacityLow

                    onClicked: pageStack.push(ruleDialog, {
                        ruleIndex: index, days: rule.days, start: rule.start, end: rule.end })

                    menu: ContextMenu {
                        MenuItem {
                            text: item.rule.on ? (page.finnish ? "Poista käytöstä" : "Disable")
                                                : (page.finnish ? "Ota käyttöön" : "Enable")
                            onClicked: {
                                var r = JSON.parse(JSON.stringify(item.rule))
                                r.on = !r.on
                                page.setRule(index, r)
                            }
                        }
                        MenuItem {
                            text: page.finnish ? "Poista" : "Delete"
                            onClicked: {
                                var i = index
                                item.remorseDelete(function () { page.removeRule(i) })
                            }
                        }
                    }

                    Column {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * x
                        anchors.verticalCenter: parent.verticalCenter

                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: page.timeText(item.rule.start) + "–" + page.timeText(item.rule.end)
                                  + (item.rule.end <= item.rule.start ? (page.finnish ? " (seuraavana päivänä)" : " (next day)") : "")
                            color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: page.daysText(item.rule.days)
                                  + (item.rule.on ? "" : (page.finnish ? " · pois käytöstä" : " · disabled"))
                            font.pixelSize: Theme.fontSizeSmall
                            color: item.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        }
                    }
                }
            }

            Label {
                visible: page.rules.length === 0
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                color: Theme.secondaryHighlightColor
                text: page.finnish ? "Ei aikatauluja. Lisää aikataulu vetämällä sivua alas."
                                    : "No schedules. Add one by pulling the page down."
            }

            Item { width: 1; height: Theme.paddingLarge }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
                text: page.finnish
                      ? "Napauta aikataulua muokataksesi sitä, paina pitkään poistaaksesi. "
                        + "Mitkä puhelut saavat soida, asetetaan kohdassa Äänet ja palaute."
                      : "Tap a schedule to edit it, long press to delete it. "
                        + "Which calls may ring is set in Sounds and feedback."
            }
        }
    }

    Component {
        id: ruleDialog

        Dialog {
            id: dialog

            property int ruleIndex
            property var days
            property int start
            property int end

            function hasDay(d) { return days.indexOf(d) >= 0 }
            function toggleDay(d) {
                var r = days.slice(0)
                var i = r.indexOf(d)
                if (i >= 0) r.splice(i, 1)
                else r.push(d)
                r.sort()
                days = r
            }
            function pickTime(which) {
                var m = which === "start" ? start : end
                var picker = pageStack.push("Sailfish.Silica.TimePickerDialog", {
                    hour: Math.floor(m / 60), minute: m % 60,
                    hourMode: DateTime.TwentyFourHours })
                picker.accepted.connect(function () {
                    dialog[which] = picker.hour * 60 + picker.minute
                })
            }

            canAccept: days.length > 0 && start !== end
            onAccepted: page.setRule(ruleIndex, {
                on: ruleIndex < 0 ? true : page.rules[ruleIndex].on,
                days: days, start: start, end: end })

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: dialogColumn.height

                Column {
                    id: dialogColumn
                    width: parent.width

                    DialogHeader {
                        acceptText: page.finnish ? "Tallenna" : "Save"
                        cancelText: page.finnish ? "Peruuta" : "Cancel"
                    }

                    SectionHeader { text: page.finnish ? "Päivät" : "Days" }

                    Row {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * x

                        Repeater {
                            model: 7

                            BackgroundItem {
                                id: dayButton
                                property int day: index + 1
                                property bool selected: dialog.hasDay(day)
                                width: parent.width / 7
                                height: Theme.itemSizeSmall
                                highlighted: down || selected
                                onClicked: dialog.toggleDay(day)

                                Label {
                                    anchors.centerIn: parent
                                    text: page.dayNames[index]
                                    font.bold: dayButton.selected
                                    color: dayButton.selected ? Theme.highlightColor : Theme.primaryColor
                                }
                            }
                        }
                    }

                    SectionHeader { text: page.finnish ? "Aika" : "Time" }

                    ValueButton {
                        label: page.finnish ? "Alkaa" : "Starts"
                        value: page.timeText(dialog.start)
                        onClicked: dialog.pickTime("start")
                    }
                    ValueButton {
                        label: page.finnish ? "Päättyy" : "Ends"
                        value: page.timeText(dialog.end)
                               + (dialog.end < dialog.start ? (page.finnish ? " seuraavana päivänä" : " next day") : "")
                        description: dialog.start === dialog.end
                                     ? (page.finnish ? "Alku- ja loppuaika ovat samat" : "The start and end times are the same") : ""
                        onClicked: dialog.pickTime("end")
                    }
                }
            }
        }
    }
}
