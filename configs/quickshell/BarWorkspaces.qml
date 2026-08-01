import QtQuick
import Quickshell.Hyprland

Item {
    id: root

    required property var screen

    readonly property Theme theme: Theme {}
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
                radius: theme.radiusSmall
                color: modelData.focused ? theme.purple : "transparent"
                border.width: modelData.focused ? 0 : 1
                border.color: theme.muted

                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: modelData.id
                    color: modelData.focused ? theme.bright : theme.dim
                    font.pixelSize: 12
                    font.family: theme.fontFamily
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
