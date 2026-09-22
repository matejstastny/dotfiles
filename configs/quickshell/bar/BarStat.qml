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

    readonly property bool hovered: hoverArea.containsMouse
    readonly property bool high: fillPct >= 80
    property alias popoutItem: popout
    property real popoutProgress: hovered ? 1 : 0

    // the row that holds these is anchored to the bar's top edge, so the bar's
    // bottom edge in local coords is just the bar height less our own offset
    readonly property real barBottom: Theme.barHeight - root.y

    implicitWidth: rowContent.implicitWidth + 8
    implicitHeight: Theme.barModuleHeight

    Row {
        id: rowContent

        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.icon
            color: root.high ? Theme.rose : (root.hovered ? Theme.bright : Theme.purple)
            font.pixelSize: Theme.barFontSize
            font.family: Theme.fontMono
            font.weight: Font.Bold

            Behavior on color {
                ColorAnimation {
                    duration: Theme.transitionDuration
                }
            }
        }

        Text {
            text: root.valueText
            color: Theme.dim
            font.pixelSize: Theme.barFontSize - 1
            font.family: Theme.fontMono
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
            duration: Theme.effectsDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.easingEffects
        }
    }

    BlobRect {
        id: popout

        visible: root.popoutProgress > 0.001
        x: -60
        y: root.barBottom - Theme.blobOverlap
        width: 200 * root.popoutProgress
        height: (popoutContent.implicitHeight + 20 + Theme.blobOverlap) * root.popoutProgress
        radius: Theme.radiusSmall
        clip: true

        Column {
            id: popoutContent

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            anchors.topMargin: Theme.blobOverlap + 10
            spacing: 8
            opacity: root.popoutProgress

            Text {
                text: root.title
                color: Theme.purple
                font.pixelSize: Theme.barFontSize - 4
                font.family: Theme.fontMono
                font.weight: Theme.weightHeading
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
                        color: Theme.purple
                    }
                }
            }

            Repeater {
                model: root.lines

                delegate: Text {
                    required property var modelData

                    width: popoutContent.width
                    text: modelData
                    color: Theme.text
                    font.pixelSize: Theme.barFontSize - 3
                    font.family: Theme.fontMono
                    font.weight: Font.Normal
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
