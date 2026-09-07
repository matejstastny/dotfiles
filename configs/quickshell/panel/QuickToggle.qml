import QtQuick
import "../"

Rectangle {
    id: root

    property string icon: ""
    property bool checked: false
    signal toggled()

    readonly property Theme theme: Theme {}

    implicitWidth: 64
    implicitHeight: 64
    radius: theme.radiusSmall
    color: checked ? Qt.rgba(theme.purple.r, theme.purple.g, theme.purple.b, 0.18) : theme.surface
    border.width: theme.borderWidth
    border.color: !root.enabled ? theme.muted : (mouseArea.containsMouse ? theme.purple : (checked ? theme.purple : theme.muted))
    opacity: root.enabled ? 1 : 0.4

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.checked ? theme.bright : theme.dim
        font.pixelSize: 20
        font.family: theme.fontFamily
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
