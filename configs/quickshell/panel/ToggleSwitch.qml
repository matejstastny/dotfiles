import QtQuick
import "../"

Rectangle {
    id: root

    property string label: ""
    property string icon: ""
    property bool checked: false
    signal toggled()

    readonly property Theme theme: Theme {}

    implicitHeight: 56
    radius: theme.radiusSmall
    color: checked ? Qt.rgba(theme.purple.r, theme.purple.g, theme.purple.b, 0.18) : theme.surface
    border.width: theme.borderWidth
    border.color: checked ? theme.purple : theme.muted

    Behavior on color { ColorAnimation { duration: 150 } }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: { console.log("DEBUG toggle clicked", root.label); root.toggled() }
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        color: root.checked ? theme.bright : theme.dim
        font.pixelSize: 16
        font.family: theme.fontFamily
        font.weight: Font.Normal
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 40
        anchors.right: pill.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: root.checked ? theme.bright : theme.text
        font.pixelSize: 13
        font.family: theme.fontFamily
        font.weight: Font.Normal
        elide: Text.ElideRight
    }

    Rectangle {
        id: pill
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 36
        height: 20
        radius: 10
        color: root.checked ? theme.purple : theme.muted

        Behavior on color { ColorAnimation { duration: 150 } }

        Rectangle {
            width: 14
            height: 14
            radius: 7
            color: theme.bright
            y: 3
            x: root.checked ? parent.width - width - 3 : 3
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
    }
}
