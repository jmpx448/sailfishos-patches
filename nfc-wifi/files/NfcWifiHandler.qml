// sfos-nfc-wifi: joins a Wi-Fi network from an NFC tag (Wi-Fi Simple
// Configuration record) or a Wi-Fi QR code read by the Camera, after asking.
// Loaded by lipstick (compositor.qml patch).
// The passphrase is kept only in memory and never logged.
import QtQuick 2.6
import Nemo.DBus 2.0
import Connman 0.2
import Nemo.Configuration 1.0

Item {
    id: handler

    readonly property bool finnish: Qt.locale().name.indexOf("fi") === 0
    property var dialog: null

    function toBytes(content) {
        if (content instanceof ArrayBuffer)
            return new Uint8Array(content)
        var out = []
        if (typeof content === "string") {
            for (var i = 0; i < content.length; ++i)
                out.push(content.charCodeAt(i) & 0xff)
        } else if (content && content.length !== undefined) {
            for (var j = 0; j < content.length; ++j)
                out.push(content[j] & 0xff)
        }
        return out
    }

    function utf8(bytes, start, len) {
        var s = ""
        for (var i = start; i < start + len; ++i)
            s += String.fromCharCode(bytes[i])
        try {
            return decodeURIComponent(escape(s))
        } catch (e) {
            return s
        }
    }

    // Wi-Fi Simple Configuration: TLVs of 2-byte type, 2-byte length.
    // Credential (0x100E) contains SSID (0x1045), Authentication Type (0x1003)
    // and Network Key (0x1027).
    function parseCredential(b, start, end) {
        var cred = { ssid: "", auth: 0, key: "", hidden: false }
        var i = start
        while (i + 4 <= end) {
            var type = (b[i] << 8) | b[i + 1]
            var len = (b[i + 2] << 8) | b[i + 3]
            var v = i + 4
            if (v + len > end)
                break
            if (type === 0x1045)
                cred.ssid = utf8(b, v, len)
            else if (type === 0x1003 && len === 2)
                cred.auth = (b[v] << 8) | b[v + 1]
            else if (type === 0x1027)
                cred.key = utf8(b, v, len)
            i = v + len
        }
        return cred
    }

    function parse(b) {
        var i = 0
        while (i + 4 <= b.length) {
            var type = (b[i] << 8) | b[i + 1]
            var len = (b[i + 2] << 8) | b[i + 3]
            if (i + 4 + len > b.length)
                break
            if (type === 0x100e)
                return parseCredential(b, i + 4, i + 4 + len)
            i += 4 + len
        }
        return null
    }

    // Authentication Type bits: 0x0001 Open, 0x0002 WPA-Personal,
    // 0x0020 WPA2-Personal (0x0022 = both). WPA3 tags also use these.
    function securityOf(cred) {
        if (cred.auth === 0x0001 && cred.key.length === 0)
            return "none"
        if ((cred.auth & 0x0022) && cred.key.length > 0)
            return "psk"
        return ""
    }

    // Wi-Fi QR code: WIFI:T:WPA;S:name;P:password;H:true;;
    // (fields in any order, \ escapes ; , : and \ itself)
    function parseWifiUri(text) {
        if (!/^WIFI:/i.test(text))
            return null
        var fields = {}
        var key = "", value = "", inValue = false
        for (var i = 5; i < text.length; ++i) {
            var c = text.charAt(i)
            if (c === "\\" && i + 1 < text.length) {
                value += text.charAt(++i)
            } else if (!inValue && c === ":") {
                key = value.toUpperCase(); value = ""; inValue = true
            } else if (c === ";") {
                if (inValue) fields[key] = value
                key = ""; value = ""; inValue = false
            } else {
                value += c
            }
        }
        var type = (fields.T || "").toUpperCase()
        return {
            ssid: fields.S || "",
            key: fields.P || "",
            hidden: (fields.H || "").toLowerCase() === "true",
            security: type === "NOPASS" || (type === "" && !fields.P) ? "none"
                      : (type === "" || type === "WPA" || type === "WPA2" || type === "SAE") ? "psk" : ""
        }
    }

    function securityLabel(security) {
        if (security === "none")
            return finnish ? "Avoin verkko" : "Open network"
        return finnish ? "WPA/WPA2, salasana mukana" : "WPA/WPA2, password included"
    }

    function join(cred, security) {
        var settings = { "Name": cred.ssid, "Security": security, "AutoConnect": "true" }
        if (security === "psk")
            settings.Passphrase = cred.key
        if (cred.hidden)
            settings.Hidden = "true"
        var path = networkManager.createServiceSync(settings, "wifi")
        console.log("sfos-nfc-wifi: network added:", path.length > 0)
    }

    function show(cred, security, fromQr) {
        if (dialog)
            dialog.closeFully()
        var component = Qt.createComponent(Qt.resolvedUrl("NfcWifiDialog.qml"))
        if (component.status !== Component.Ready) {
            console.warn("sfos-nfc-wifi:", component.errorString())
            return
        }
        dialog = component.createObject(handler, {
            "ssid": cred.ssid,
            "securityText": securityLabel(security),
            "finnish": finnish
        })
        dialog.accepted.connect(function() {
            handler.join(cred, security)
            // tells the Camera's QR page to close
            if (fromQr)
                qrResult.value = "connected " + Date.now()
        })
        dialog.shouldBeVisible = true
    }

    NetworkManager {
        id: networkManager
    }

    ConfigurationValue {
        id: qrResult
        key: "/apps/sfos-nfc-wifi/qr-result"
    }

    // The Camera's QR page (patched) writes the code here; it is cleared at once.
    ConfigurationValue {
        id: qrRequest
        key: "/apps/sfos-nfc-wifi/qr-request"
        defaultValue: ""
        onValueChanged: {
            var text = value ? String(value) : ""
            if (text.length === 0)
                return
            qrRequest.value = ""
            var cred = handler.parseWifiUri(text)
            var usable = !!(cred && cred.ssid.length > 0 && cred.security.length > 0
                            && (cred.security === "none" || cred.key.length > 0))
            console.log("sfos-nfc-wifi: QR code, usable:", usable)
            if (usable)
                handler.show(cred, cred.security, true)
        }
    }

    DBusAdaptor {
        bus: DBus.SystemBus
        service: "org.jmpx448.nfcwifi"
        path: "/org/jmpx448/nfcwifi"
        iface: "org.jmpx448.nfcwifi"
        xml: '<interface name="org.jmpx448.nfcwifi">'
             + '<method name="handleWsc">'
             + '<arg name="media_type" type="s" direction="in"/>'
             + '<arg name="content" type="ay" direction="in"/>'
             + '</method></interface>'

        function handleWsc(mediaType, content) {
            var bytes = handler.toBytes(content)
            var cred = handler.parse(bytes)
            var security = cred ? handler.securityOf(cred) : ""
            console.log("sfos-nfc-wifi: tag", typeof content, bytes.length, "bytes, usable:",
                        !!(cred && cred.ssid.length > 0 && security.length > 0))
            if (cred && cred.ssid.length > 0 && security.length > 0)
                handler.show(cred, security)
        }
    }
}
