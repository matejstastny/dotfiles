import QtQuick
import "../"

Item {
    id: root
    required property var modelData
    required property int index

    readonly property Theme theme: Theme {}
    readonly property bool current: ListView.isCurrentItem

    width: ListView.view ? ListView.view.width : 200
    height: 40

    Rectangle {
        anchors.fill: parent
        radius: theme.radiusSmall
        color: root.current ? Qt.rgba(theme.purple.r, theme.purple.g, theme.purple.b, 0.18) : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    Text {
        id: iconText
        visible: text.length > 0
        text: root.modelData.icon || ""
        color: root.current ? theme.purple : theme.dim
        font.pixelSize: 14
        font.family: theme.fontFamily
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        id: subtitleText
        visible: text.length > 0
        text: root.modelData.subtitle || ""
        color: theme.dim
        font.pixelSize: 11
        font.family: theme.fontFamily
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: root.modelData.label || ""
        color: root.current ? theme.bright : theme.text
        font.pixelSize: 13
        font.family: theme.fontFamily
        elide: Text.ElideRight
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: iconText.visible ? iconText.right : parent.left
        anchors.leftMargin: iconText.visible ? 8 : 10
        anchors.right: subtitleText.visible ? subtitleText.left : parent.right
        anchors.rightMargin: subtitleText.visible ? 8 : 10
    }
}
