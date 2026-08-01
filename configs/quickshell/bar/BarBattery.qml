import QtQuick
import Quickshell.Services.UPower
import "../"

Item {
    id: root

    readonly property Theme theme: Theme {}
    readonly property var device: UPower.displayDevice
    readonly property bool present: device && device.isLaptopBattery && device.isPresent
    readonly property int pct: present ? Math.round(device.percentage * 100) : 0
    readonly property bool charging: present && device.state === UPowerDeviceState.Charging

    visible: present
    implicitWidth: visible ? label.implicitWidth + 8 : 0
    implicitHeight: 38

    readonly property var icons: ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    readonly property string icon: charging ? "󰂄" : icons[Math.min(9, Math.floor(pct / 10))]

    Text {
        id: label
        anchors.centerIn: parent
        text: root.icon + " " + root.pct + "%"
        color: root.pct <= 15 && !root.charging ? theme.rose : theme.text
        font.pixelSize: 15
        font.family: theme.fontFamily
        font.weight: Font.Normal
    }
}
