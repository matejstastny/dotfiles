import QtQuick
import Quickshell
import "../"

Item {
    id: root

    readonly property bool hovered: hoverArea.containsMouse

    implicitWidth: label.implicitWidth + 8
    implicitHeight: Theme.barModuleHeight

    Text {
        id: label
        anchors.centerIn: parent
        text: ""
        color: root.hovered ? Theme.bright : Theme.purple
        font.pixelSize: Theme.barFontSize + 2
        font.family: Theme.fontMono
        font.weight: Font.Normal

        Behavior on color { ColorAnimation { duration: Theme.transitionDuration } }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "powermenu", "toggle"])
    }
}
