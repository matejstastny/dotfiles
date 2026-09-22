import QtQuick
import "../"

Rectangle {
    id: root

    property string icon: ""
    property bool checked: false
    signal toggled()

    implicitWidth: 64
    implicitHeight: 64
    radius: Theme.radiusSmall
    color: checked ? Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.18) : Theme.surface
    border.width: Theme.borderWidth
    border.color: !root.enabled ? Theme.muted : (mouseArea.containsMouse ? Theme.purple : (checked ? Theme.purple : Theme.muted))
    opacity: root.enabled ? 1 : 0.4

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.checked ? Theme.bright : Theme.dim
        font.pixelSize: 20
        font.family: Theme.fontMono
        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }

    scale: mouseArea.pressed ? 0.92 : (mouseArea.containsMouse ? 1.04 : 1)
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
}
