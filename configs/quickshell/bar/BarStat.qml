import QtQuick
import "../"

Item {
    id: root

    property string icon: ""
    property string valueText: ""
    property string title: ""
    property var lines: []
    property var history: []

    readonly property Theme theme: Theme {}
    readonly property bool hovered: hoverArea.containsMouse
    property alias popoutItem: popout

    implicitWidth: rowContent.implicitWidth + 12
    implicitHeight: theme.barModuleHeight

    Row {
        id: rowContent
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.icon
            color: theme.text
            font.pixelSize: theme.barFontSize
            font.family: theme.fontFamily
            font.weight: Font.Bold
        }
        Text {
            text: root.valueText
            color: theme.text
            font.pixelSize: theme.barFontSize - 1
            font.family: theme.fontFamily
            font.weight: Font.Normal
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
    }

    Rectangle {
        id: popout
        visible: root.hovered
        y: 38
        x: -60
        width: 200
        height: popoutContent.implicitHeight + 20
        radius: theme.radiusSmall
        color: theme.surface
        border.width: theme.borderWidth
        border.color: theme.muted

        Column {
            id: popoutContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            spacing: 8

            Text {
                text: root.title
                color: theme.purple
                font.bold: true
                font.pixelSize: theme.barFontSize - 4
                font.family: theme.fontFamily
                font.weight: Font.Normal
            }

            Row {
                width: parent.width
                height: 32
                spacing: 2

                Repeater {
                    model: root.history
                    delegate: Rectangle {
                        required property var modelData
                        anchors.bottom: parent.bottom
                        width: 4
                        height: Math.max(2, (modelData / 100) * 32)
                        radius: 1
                        color: theme.purple
                    }
                }
            }

            Repeater {
                model: root.lines
                delegate: Text {
                    required property var modelData
                    width: popoutContent.width
                    text: modelData
                    color: theme.text
                    font.pixelSize: theme.barFontSize - 3
                    font.family: theme.fontFamily
                    font.weight: Font.Normal
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
