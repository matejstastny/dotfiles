import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../common"

Item {
    id: root

    required property string script
    required property int interval
    property string onClickCommand: ""

    property string text: ""
    property string tooltip: ""
    property string statusClass: ""
    property string title: ""
    property string headline: ""
    property var lines: []
    readonly property bool hovered: hoverArea.containsMouse || popoutArea.containsMouse
    readonly property bool active: statusClass === "recording" || statusClass === "connected" || statusClass === "running"
    property alias popoutItem: popout
    property real popoutProgress: hovered && title !== "" ? 1 : 0
    readonly property real barBottom: Theme.barHeight - root.y

    visible: text !== ""
    implicitWidth: visible ? label.implicitWidth + 8 : 0
    implicitHeight: Theme.barModuleHeight

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: [root.script]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const parsed = JSON.parse(data)
                    root.text = parsed.text || ""
                    root.tooltip = parsed.tooltip || ""
                    root.statusClass = parsed.class || ""
                    root.title = parsed.title || ""
                    root.headline = parsed.headline || ""
                    root.lines = parsed.lines || []
                } catch (e) {
                    root.text = ""
                }
            }
        }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.statusClass === "recording" ? Theme.rose
             : (root.active ? Theme.purple : Theme.dim)
        font.pixelSize: Theme.barFontSize
        font.family: Theme.fontMono
        font.weight: Font.Normal

        Behavior on color { ColorAnimation { duration: Theme.transitionDuration } }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.onClickCommand !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: root.onClickCommand !== ""
        onClicked: Quickshell.execDetached(["sh", "-c", root.onClickCommand])
    }

    MouseArea {
        id: popoutArea
        x: (root.width - 270) / 2
        y: root.barBottom - Theme.blobOverlap
        width: 270
        height: popout.height
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
        x: (root.width - width) / 2
        y: root.barBottom - Theme.blobOverlap
        width: 270 * root.popoutProgress
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

            Row {
                spacing: 7

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6
                    height: 6
                    radius: 3
                    color: root.statusClass === "offline" ? Theme.rose : Theme.purple
                }

                Text {
                    text: root.title
                    color: Theme.purple
                    font.pixelSize: Theme.sizeLabel
                    font.family: Theme.fontMono
                    font.weight: Theme.weightHeading
                }
            }

            Text {
                visible: root.headline !== ""
                width: parent.width
                text: root.headline
                color: root.statusClass === "offline" ? Theme.rose : Theme.bright
                font.pixelSize: Theme.sizeBody + 1
                font.family: Theme.fontSans
                font.weight: Theme.weightHeading
                elide: Text.ElideRight
            }

            Repeater {
                model: root.lines

                delegate: Text {
                    required property var modelData
                    width: popoutContent.width
                    text: modelData
                    color: Theme.dim
                    font.pixelSize: Theme.sizeLabel
                    font.family: Theme.fontMono
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
