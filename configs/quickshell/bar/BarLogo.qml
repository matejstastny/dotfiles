import QtQuick
import Quickshell
import "../"

Item {
    id: root

    readonly property Theme theme: Theme {}
    readonly property bool hovered: hoverArea.containsMouse

    implicitWidth: label.implicitWidth + 8
    implicitHeight: theme.barModuleHeight

    Text {
        id: label
        anchors.centerIn: parent
        text: ""
        color: root.hovered ? theme.bright : theme.purple
        font.pixelSize: theme.barFontSize + 2
        font.family: theme.fontFamily
        font.weight: Font.Normal

        Behavior on color { ColorAnimation { duration: theme.transitionDuration } }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "powermenu", "toggle"])
    }
}
