import QtQuick
import "../"

Item {
    id: root

    property string icon: ""
    property string valueText: ""
    property string title: ""
    property var lines: []
    property var history: []
    property real fillPct: 0

    readonly property Theme theme: Theme {}
    readonly property bool hovered: hoverArea.containsMouse
    property alias popoutItem: popout

    implicitWidth: rowContent.implicitWidth + 20
    implicitHeight: theme.barModuleHeight

    Rectangle {
        id: pill
        anchors.fill: parent
        anchors.topMargin: 5
        anchors.bottomMargin: 5
        radius: theme.radiusSmall
        color: theme.surface
        border.width: theme.borderWidth
        border.color: theme.muted
        clip: true

        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 3
            height: 2
            radius: 1
            width: Math.max(height, (parent.width - 6) * Math.min(1, Math.max(0, root.fillPct / 100)))
            color: theme.purple

            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        }

        Row {
            id: rowContent
            anchors.centerIn: parent
            spacing: 4

            Text {
                text: root.icon
                color: root.hovered ? theme.bright : theme.purple
                font.pixelSize: theme.barFontSize
                font.family: theme.fontFamily
                font.weight: Font.Bold

                Behavior on color { ColorAnimation { duration: theme.transitionDuration } }
            }
            Text {
                text: root.valueText
                color: theme.dim
                font.pixelSize: theme.barFontSize - 1
                font.family: theme.fontFamily
                font.weight: Font.Normal
            }
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
