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
    readonly property bool low: pct <= 15 && !charging

    visible: present
    implicitWidth: visible ? rowContent.implicitWidth + 20 : 0
    implicitHeight: theme.barModuleHeight

    readonly property var icons: ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    readonly property string icon: charging ? "󰂄" : icons[Math.min(9, Math.floor(pct / 10))]

    Rectangle {
        id: pill
        anchors.fill: parent
        anchors.topMargin: 5
        anchors.bottomMargin: 5
        radius: theme.radiusSmall
        color: theme.surface
        border.width: theme.borderWidth
        border.color: theme.muted
        clip: true

        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 3
            height: 2
            radius: 1
            width: Math.max(height, (parent.width - 6) * Math.min(1, root.pct / 100))
            color: root.low ? theme.rose : theme.purple

            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        }

        Row {
            id: rowContent
            anchors.centerIn: parent
            spacing: 4

            Text {
                text: root.icon
                color: root.low ? theme.rose : theme.purple
                font.pixelSize: theme.barFontSize
                font.family: theme.fontFamily
                font.weight: Font.Bold
            }
            Text {
                text: root.pct.toString().padStart(2, " ") + "%"
                color: root.low ? theme.rose : theme.dim
                font.pixelSize: theme.barFontSize - 1
                font.family: theme.fontFamily
                font.weight: Font.Normal
            }
        }
    }
}
