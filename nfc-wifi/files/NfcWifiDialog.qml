// sfos-nfc-wifi: confirmation dialog, in the style of lipstick's NFC dialog.
import QtQuick 2.6
import Sailfish.Silica 1.0
import com.jolla.lipstick 0.1
import Sailfish.Lipstick 1.0
import org.nemomobile.lipstick 0.1
import "file:///usr/share/lipstick-jolla-home-qt5/systemwindow"

SystemWindow {
    id: root

    property string ssid
    property string securityText
    property bool finnish

    signal accepted()

    function closeFully() {
        root.shouldBeVisible = false
    }

    contentHeight: content.height
    onHidden: root.destroy()

    // Lipstick's own dialogs get their background from a separate window;
    // this one is a plain item in the compositor, so it draws its own.
    opacity: _windowOpacity

    Rectangle {
        // dims the rest of the screen; a tap outside cancels
        anchors.fill: parent
        color: "black"
        opacity: 0.6

        MouseArea {
            anchors.fill: parent
            onClicked: closeFully()
        }
    }

    Rectangle {
        width: parent.width
        height: root.contentHeight + Theme.paddingLarge
        color: Theme.overlayBackgroundColor

        MouseArea {
            // keeps taps on the panel from reaching the screen below
            anchors.fill: parent
        }
    }

    SystemDialogLayout {
        contentHeight: content.height
        onDismiss: closeFully()

        Column {
            id: content

            width: parent.width
            topPadding: Theme.paddingLarge

            SystemDialogHeader {
                id: header
                title: finnish ? "Yhdistetäänkö WLAN-verkkoon?" : "Connect to Wi-Fi network?"
                description: root.ssid + "\n" + root.securityText
                semiTight: true
            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }

            Row {
                width: parent.width
                height: Math.max(cancelButton.implicitHeight, connectButton.implicitHeight)

                SystemDialogTextButton {
                    id: cancelButton
                    width: header.width / 2
                    height: parent.height
                    text: finnish ? "Peruuta" : "Cancel"
                    onClicked: closeFully()
                }

                SystemDialogTextButton {
                    id: connectButton
                    width: header.width / 2
                    height: parent.height
                    text: finnish ? "Yhdistä" : "Connect"
                    onClicked: {
                        root.accepted()
                        closeFully()
                    }
                }
            }
        }
    }

    Connections {
        target: Lipstick.compositor
        onDisplayOff: closeFully()
    }
}
