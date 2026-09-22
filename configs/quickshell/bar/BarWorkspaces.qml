import QtQuick
import Quickshell.Hyprland
import "../"

Item {
    id: root

    required property var screen

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            Hyprland.dispatch(wheel.angleDelta.y > 0 ? "workspace e-1" : "workspace e+1")
        }
    }

    Row {
        id: row
        spacing: 4

        Repeater {
            model: Hyprland.workspaces
            delegate: Rectangle {
                required property var modelData
                readonly property bool onThisScreen: modelData.monitor && modelData.monitor.name === root.screen.name

                visible: onThisScreen
                width: 26
                height: 26
                radius: Theme.radiusSmall
                color: modelData.focused ? Theme.purple : "transparent"
                border.width: modelData.focused ? 0 : 1
                border.color: Theme.muted

                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: modelData.id
                    color: modelData.focused ? Theme.bright : Theme.dim
                    font.pixelSize: Theme.barFontSize - 3
                    font.family: Theme.fontMono
                    font.weight: Font.Normal
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.activate()
                }
            }
        }
    }
}
