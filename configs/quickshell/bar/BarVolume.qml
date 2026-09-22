import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../"
import "../common"

Item {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink && sink.audio
    readonly property bool muted: ready && sink.audio.muted
    readonly property int pct: ready ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool hovered: hoverArea.containsMouse || popoutArea.containsMouse
    readonly property real barBottom: Theme.barHeight - root.y
    readonly property string deviceName: ready ? (sink.description || sink.nickname || sink.name || "default output") : "no output device"
    property alias popoutItem: popout
    property real popoutProgress: hovered ? 1 : 0

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    implicitWidth: rowContent.implicitWidth + 8
    implicitHeight: Theme.barModuleHeight

    Row {
        id: rowContent
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.muted ? "󰝟" : "󰕾"
            color: root.muted ? Theme.rose : (root.hovered ? Theme.bright : Theme.purple)
            font.pixelSize: Theme.barFontSize
            font.family: Theme.fontMono
            font.weight: Font.Bold

            Behavior on color { ColorAnimation { duration: Theme.transitionDuration } }
        }
        Text {
            visible: !root.muted
            text: root.pct.toString().padStart(2, " ") + "%"
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
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: Quickshell.execDetached(["pavucontrol"])
        onWheel: wheel => {
            Quickshell.execDetached(["qs", "ipc", "call", "osd", "volume", wheel.angleDelta.y > 0 ? "raise" : "lower"])
        }
    }

    MouseArea {
        id: popoutArea
        x: -80
        y: root.barBottom - Theme.blobOverlap
        width: 230
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
        x: -80
        y: root.barBottom - Theme.blobOverlap
        width: 230 * root.popoutProgress
        height: (content.implicitHeight + 20 + Theme.blobOverlap) * root.popoutProgress
        radius: Theme.radiusSmall
        clip: true

        Column {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            anchors.topMargin: Theme.blobOverlap + 10
            spacing: 5
            opacity: root.popoutProgress

            Text {
                text: "audio output"
                color: Theme.purple
                font.pixelSize: Theme.sizeLabel
                font.family: Theme.fontMono
                font.weight: Theme.weightHeading
            }
            Text {
                width: parent.width
                text: root.deviceName
                color: Theme.bright
                font.pixelSize: Theme.sizeBody
                font.family: Theme.fontSans
                font.weight: Theme.weightHeading
                elide: Text.ElideRight
            }
            Text {
                text: root.muted ? "muted" : root.pct + "% volume"
                color: root.muted ? Theme.rose : Theme.dim
                font.pixelSize: Theme.sizeLabel
                font.family: Theme.fontMono
            }
        }
    }
}
