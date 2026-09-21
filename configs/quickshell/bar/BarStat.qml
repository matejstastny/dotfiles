import QtQuick
import "../"
import "../common"

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
    readonly property bool high: fillPct >= 80
    property alias popoutItem: popout
    property real popoutProgress: hovered ? 1 : 0

    // the row that holds these is anchored to the bar's top edge, so the bar's
    // bottom edge in local coords is just the bar height less our own offset
    readonly property real barBottom: theme.barHeight - root.y

    implicitWidth: rowContent.implicitWidth + 8
    implicitHeight: theme.barModuleHeight

    Row {
        id: rowContent

        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.icon
            color: root.high ? root.theme.rose : (root.hovered ? root.theme.bright : root.theme.purple)
            font.pixelSize: root.theme.barFontSize
            font.family: root.theme.fontFamily
            font.weight: Font.Bold

            Behavior on color {
                ColorAnimation {
                    duration: root.theme.transitionDuration
                }
            }
        }

        Text {
            text: root.valueText
            color: root.theme.dim
            font.pixelSize: root.theme.barFontSize - 1
            font.family: root.theme.fontFamily
            font.weight: Font.Normal
        }
    }

    MouseArea {
        id: hoverArea

        anchors.fill: parent
        hoverEnabled: true
    }

    Behavior on popoutProgress {
        NumberAnimation {
            duration: theme.effectsDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: theme.easingEffects
        }
    }

    BlobRect {
        id: popout

        visible: root.popoutProgress > 0.001
        x: -60
        y: root.barBottom - root.theme.blobOverlap
        width: 200 * root.popoutProgress
        height: (popoutContent.implicitHeight + 20 + root.theme.blobOverlap) * root.popoutProgress
        radius: root.theme.radiusSmall
        clip: true

        Column {
            id: popoutContent

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            anchors.topMargin: root.theme.blobOverlap + 10
            spacing: 8
            opacity: root.popoutProgress

            Text {
                text: root.title
                color: root.theme.purple
                font.bold: true
                font.pixelSize: root.theme.barFontSize - 4
                font.family: root.theme.fontFamily
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
                        color: root.theme.purple
                    }
                }
            }

            Repeater {
                model: root.lines

                delegate: Text {
                    required property var modelData

                    width: popoutContent.width
                    text: modelData
                    color: root.theme.text
                    font.pixelSize: root.theme.barFontSize - 3
                    font.family: root.theme.fontFamily
                    font.weight: Font.Normal
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
