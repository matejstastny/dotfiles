import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Row {
    id: root

    required property var screen

    spacing: 4

    readonly property var activeMenuBox: {
        for (let i = 0; i < trayRepeater.count; i++) {
            const item = trayRepeater.itemAt(i)
            if (item && item.menu.menuOpen) return item.menu.boxItem
        }
        return null
    }

    Repeater {
        id: trayRepeater
        model: SystemTray.items
        delegate: Item {
            id: trayItem
            required property var modelData
            required property int index
            property alias menu: menu

            width: 22
            height: 38

            IconImage {
                anchors.centerIn: parent
                width: 20
                height: 20
                source: trayItem.modelData.icon
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        trayItem.modelData.activate()
                    } else if (trayItem.modelData.hasMenu) {
                        menu.toggle()
                    }
                }
            }

            BarTrayMenu {
                id: menu
                popoutName: "traymenu|" + root.screen.name + "|" + trayItem.index
                menuHandle: trayItem.modelData.hasMenu ? trayItem.modelData.menu : null
            }
        }
    }
}
