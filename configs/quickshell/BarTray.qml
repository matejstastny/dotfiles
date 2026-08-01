import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Row {
    id: root

    spacing: 8

    Repeater {
        model: SystemTray.items
        delegate: Item {
            id: trayItem
            required property var modelData
            required property int index

            width: 18
            height: 38

            IconImage {
                anchors.centerIn: parent
                width: 16
                height: 16
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
                popoutName: "traymenu" + trayItem.index
                menuHandle: trayItem.modelData.hasMenu ? trayItem.modelData.menu : null
            }
        }
    }
}
