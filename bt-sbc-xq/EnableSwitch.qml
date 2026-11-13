// SPDX-FileCopyrightText: 2026 Jolla Mobile Ltd
//
// SPDX-License-Identifier: BSD-3-Clause
//
// Top menu switch for bt-sbc-xq.service, adapted from the Inari Blue switch
// (/usr/share/jolla-settings/pages/inari_blue/EnableSwitch.qml): off stops and masks the unit,
// so it also stays off after a reboot; on unmasks and starts it.
//
// Redistribution and use in source and binary forms, with or without modification, are permitted
// provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of
//    conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of
//    conditions and the following disclaimer in the documentation and/or other materials provided
//    with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to
//    endorse or promote products derived from this software without specific prior written
//    permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
// FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
// IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
import com.jolla.settings 1.0

SettingsToggle {
    id: root

    name: "SBC XQ"
    icon.source: "image://theme/icon-m-headset"
    onToggled: unit.toggle()
    checked: false

    DBusInterface {
        id: unit

        bus: DBus.SessionBus
        service: "org.freedesktop.systemd1"
        iface: "org.freedesktop.systemd1.Manager"
        path: "/org/freedesktop/systemd1"

        signalsEnabled: true

        function update() {
            call('GetUnitFileState', "bt-sbc-xq.service", function(state) {
                root.checked = state != "masked"
            })
        }

        function toggle() {
            if (root.checked) {
                call('StopUnit', ['bt-sbc-xq.service', 'replace'], function(reply) {
                    typedCall('MaskUnitFiles', [
                        {'type': 'as', 'value': ['bt-sbc-xq.service']},
                        {'type': 'b', 'value': false},
                        {'type': 'b', 'value': false},
                    ])
                })
            } else {
                typedCall('UnmaskUnitFiles', [
                    {'type': 'as', 'value': ['bt-sbc-xq.service']},
                    {'type': 'b', 'value': false}
                ], function(reply) {
                    call('StartUnit', ['bt-sbc-xq.service', 'replace'])
                })
            }
        }

        function unitFilesChanged() {
            update()
        }

        Component.onCompleted: {
            call('Subscribe', undefined)
            update()
        }
    }
}
