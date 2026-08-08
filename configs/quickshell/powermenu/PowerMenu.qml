import QtQuick
import Quickshell
import "../common"

PopupWindow {
    id: root
    popoutName: "powermenu"
    title: "system"
    implicitWidth: 560
    implicitHeight: 200

    property int currentIndex: 0

    readonly property var actions: [
        { icon: "󰌾", label: "lock", danger: false, cmd: ["hyprlock"] },
        { icon: "󰒲", label: "suspend", danger: false, cmd: ["systemctl", "suspend"] },
        { icon: "󰍃", label: "logout", danger: false, cmd: ["pkill", "-x", "Hyprland"] },
        { icon: "󰜉", label: "reboot", danger: true, cmd: ["systemctl", "reboot"] },
        { icon: "󰐥", label: "shutdown", danger: true, cmd: ["systemctl", "poweroff"] }
    ]

    function fire(index) {
        Quickshell.execDetached(root.actions[index].cmd)
        root.closeRequested()
    }

    Item {
        anchors.fill: parent
        focus: root.open

        Keys.onLeftPressed: root.currentIndex = Math.max(0, root.currentIndex - 1)
        Keys.onRightPressed: root.currentIndex = Math.min(root.actions.length - 1, root.currentIndex + 1)
        Keys.onEscapePressed: root.closeRequested()
        Keys.onReturnPressed: root.fire(root.currentIndex)
        Keys.onEnterPressed: root.fire(root.currentIndex)

        Row {
            anchors.centerIn: parent
            spacing: 16

            Repeater {
                model: root.actions
                delegate: IconButton {
                    required property var modelData
                    required property int index
                    implicitWidth: 84
                    implicitHeight: 84
                    icon: modelData.icon
                    label: modelData.label
                    danger: modelData.danger
                    active: index === root.currentIndex
                    onClicked: root.fire(index)
                }
            }
        }
    }

    onOpenChanged: {
        if (open) root.currentIndex = 0
    }
}
