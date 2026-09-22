import QtQuick
import "../"

Item {
    id: root
    required property var modelData
    required property int index

    readonly property bool current: ListView.isCurrentItem

    width: ListView.view ? ListView.view.width : 200
    height: 40

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: root.current ? Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.18) : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    Text {
        id: iconText
        visible: text.length > 0
        text: root.modelData.icon || ""
        color: root.current ? Theme.purple : Theme.dim
        font.pixelSize: 14
        font.family: Theme.fontMono
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        id: subtitleText
        visible: text.length > 0
        text: root.modelData.subtitle || ""
        color: Theme.dim
        font.pixelSize: 11
        font.family: Theme.fontMono
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: root.modelData.label || ""
        color: root.current ? Theme.bright : Theme.text
        font.pixelSize: 13
        font.family: Theme.fontMono
        elide: Text.ElideRight
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: iconText.visible ? iconText.right : parent.left
        anchors.leftMargin: iconText.visible ? 8 : 10
        anchors.right: subtitleText.visible ? subtitleText.left : parent.right
        anchors.rightMargin: subtitleText.visible ? 8 : 10
    }
}
