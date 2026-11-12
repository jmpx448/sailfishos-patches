import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

// Automatic VPN. The trusted networks are a JSON string in dconf; vpn-auto.service
// (/usr/bin/vpn-auto) follows the network and connects or disconnects the VPN. The service also
// writes the current network, the VPNs and the VPN's state for this page.
Page {
    id: page

    readonly property bool finnish: Qt.locale().name.indexOf("fi") === 0
    property var trusted: []
    property var current: ({})
    property var vpnNames: []

    function parse(text, fallback) {
        try { return JSON.parse(text) } catch (e) { return fallback }
    }
    function saveTrusted(t) {
        trusted = t
        trustedConfig.value = JSON.stringify(t)
    }
    // The end of the router's address tells two networks with the same name apart.
    function routerText(gw) {
        return gw ? (finnish ? "reititin …" : "router …") + gw.substr(9).toUpperCase() : ""
    }
    function stateText(s) {
        if (s === "ready") return finnish ? "Yhdistetty" : "Connected"
        if (s === "configuration" || s === "association") return finnish ? "Yhdistetään" : "Connecting"
        if (s === "failure") return finnish ? "Virhe" : "Failed"
        if (s === "") return "–"
        return finnish ? "Ei yhteyttä" : "Not connected"
    }
    function networkText(n) {
        if (n.type === "wifi") return n.ssid
        if (n.type === "cellular") return finnish ? "Mobiilidata" : "Mobile data"
        if (n.type === "ethernet") return "Ethernet"
        return finnish ? "Ei yhteyttä" : "Not connected"
    }

    ConfigurationValue {
        id: enabledConfig
        key: "/apps/vpn-auto/enabled"
        defaultValue: false
    }
    ConfigurationValue {
        id: trustedConfig
        key: "/apps/vpn-auto/trusted"
        defaultValue: "[]"
        onValueChanged: page.trusted = page.parse(value, [])
    }
    ConfigurationValue {
        id: vpnConfig
        key: "/apps/vpn-auto/vpn"
        defaultValue: ""
    }
    ConfigurationValue {
        id: currentConfig
        key: "/apps/vpn-auto/current"
        defaultValue: ""
        onValueChanged: page.current = page.parse(value, {})
    }
    ConfigurationValue {
        id: vpnsConfig
        key: "/apps/vpn-auto/vpns"
        defaultValue: "[]"
        onValueChanged: page.vpnNames = page.parse(value, [])
    }
    ConfigurationValue {
        id: stateConfig
        key: "/apps/vpn-auto/state"
        defaultValue: ""
    }

    Component.onCompleted: {
        trusted = parse(trustedConfig.value, [])
        current = parse(currentConfig.value, {})
        vpnNames = parse(vpnsConfig.value, [])
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width

            PageHeader { title: page.finnish ? "Automaattinen VPN" : "Automatic VPN" }

            TextSwitch {
                text: page.finnish ? "VPN automaattisesti" : "VPN automatically"
                description: page.finnish
                             ? "VPN kytketään päälle mobiilidatalla ja vieraissa WLAN-verkoissa ja pois "
                               + "luotetuissa verkoissa, samoin kuin VPN-kytkimellä. Jos käännät kytkintä "
                               + "itse, VPN pysyy niin seuraavaan verkon vaihtoon asti."
                             : "The VPN is turned on on mobile data and other Wi-Fi networks, and off on "
                               + "trusted networks, as with the VPN switch. If you turn the switch yourself, "
                               + "the VPN stays so until the network changes."
                automaticCheck: false
                checked: !!enabledConfig.value
                onClicked: enabledConfig.value = !enabledConfig.value
            }

            ComboBox {
                visible: page.vpnNames.length > 1
                label: "VPN"
                currentIndex: Math.max(0, page.vpnNames.indexOf(vpnConfig.value))
                menu: ContextMenu {
                    Repeater {
                        model: page.vpnNames
                        MenuItem { text: modelData }
                    }
                }
                onCurrentIndexChanged: {
                    if (visible && page.vpnNames[currentIndex] !== undefined)
                        vpnConfig.value = page.vpnNames[currentIndex]
                }
            }
            DetailItem {
                visible: page.vpnNames.length === 1
                label: "VPN"
                value: page.vpnNames.length === 1 ? page.vpnNames[0] : ""
            }
            DetailItem {
                visible: page.vpnNames.length > 0
                label: page.finnish ? "VPN nyt" : "VPN now"
                value: page.stateText(stateConfig.value)
            }
            Label {
                visible: page.vpnNames.length === 0
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                color: Theme.secondaryHighlightColor
                text: page.finnish ? "Ei VPN-yhteyksiä. Lisää VPN kohdassa Asetukset → VPN."
                                    : "No VPNs. Add one in Settings → VPN."
            }

            SectionHeader { text: page.finnish ? "Nykyinen verkko" : "Current network" }

            DetailItem {
                label: page.finnish ? "Verkko" : "Network"
                value: page.networkText(page.current)
            }
            DetailItem {
                visible: page.current.type === "wifi"
                label: page.finnish ? "Luotettu" : "Trusted"
                value: page.current.trusted ? (page.finnish ? "Kyllä" : "Yes") : (page.finnish ? "Ei" : "No")
            }
            Button {
                visible: page.current.type === "wifi" && !!page.current.gw && !page.current.trusted
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.finnish ? "Lisää luotetuksi" : "Add as trusted"
                onClicked: page.saveTrusted(page.trusted.concat([{ ssid: page.current.ssid, gw: page.current.gw }]))
            }
            Label {
                visible: page.current.type === "wifi" && !page.current.gw
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
                text: page.finnish ? "Reitittimen osoitetta ei saatu, joten verkkoa ei voi lisätä luotetuksi."
                                    : "The router's address is not known, so the network cannot be added as trusted."
            }

            SectionHeader { text: page.finnish ? "Luotetut verkot" : "Trusted networks" }

            Repeater {
                model: page.trusted.length

                ListItem {
                    id: item
                    property var network: page.trusted[index]
                    contentHeight: Theme.itemSizeMedium

                    menu: ContextMenu {
                        MenuItem {
                            text: page.finnish ? "Poista" : "Delete"
                            onClicked: {
                                var i = index
                                item.remorseDelete(function () {
                                    var t = page.trusted.slice(0)
                                    t.splice(i, 1)
                                    page.saveTrusted(t)
                                })
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
                            text: item.network.ssid
                            color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: page.routerText(item.network.gw)
                            font.pixelSize: Theme.fontSizeSmall
                            color: item.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        }
                    }
                }
            }

            Label {
                visible: page.trusted.length === 0
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                color: Theme.secondaryHighlightColor
                text: page.finnish ? "Ei luotettuja verkkoja. Yhdistä esimerkiksi kotiverkkoon ja lisää se yllä."
                                    : "No trusted networks. Connect to, for example, your home network and add it above."
            }

            Item { width: 1; height: Theme.paddingLarge }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
                text: page.finnish
                      ? "Verkko tunnistetaan nimestä ja reitittimen laiteosoitteesta, joten samanniminen "
                        + "vieras verkko ei ole luotettu. Paina luotettua verkkoa pitkään poistaaksesi sen. "
                        + "Kun verkko vaihtuu, liikenne kulkee muutaman sekunnin ilman VPN:ää."
                      : "A network is recognised by its name and the hardware address of its router, so "
                        + "another network with the same name is not trusted. Long press a trusted network "
                        + "to delete it. When the network changes, traffic goes without the VPN for a few "
                        + "seconds."
            }
        }
    }
}
