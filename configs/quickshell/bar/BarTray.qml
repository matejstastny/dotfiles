import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../"

Item {
    id: root

    visible: SystemTray.items.values.length > 0
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: Theme.barModuleHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10

        Repeater {
            model: SystemTray.items

            Item {
                id: trayIcon
                required property SystemTrayItem modelData
                width: 16
                height: 16
                anchors.verticalCenter: parent.verticalCenter
                scale: hoverArea.containsMouse ? 1.12 : 1
                Behavior on scale { NumberAnimation { duration: Theme.transitionDuration; easing.type: Easing.OutCubic } }

                IconImage {
                    anchors.fill: parent
                    source: trayIcon.modelData.icon
                    smooth: true
                    asynchronous: true
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            trayIcon.modelData.activate()
                        } else if (mouse.button === Qt.MiddleButton) {
                            trayIcon.modelData.secondaryActivate()
                        } else if (mouse.button === Qt.RightButton && trayIcon.modelData.hasMenu) {
                            trayIcon.modelData.display(trayIcon.QsWindow.window, mouse.x, mouse.y)
                        }
                    }
                }
            }
        }
    }
}
