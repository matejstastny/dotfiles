import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../"

Item {
    id: root

    readonly property Theme theme: Theme {}
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink && sink.audio
    readonly property bool muted: ready && sink.audio.muted
    readonly property int pct: ready ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool hovered: hoverArea.containsMouse

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

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
            width: Math.max(height, (parent.width - 6) * (root.muted ? 0 : Math.min(1, root.pct / 100)))
            color: theme.purple

            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        }

        Row {
            id: rowContent
            anchors.centerIn: parent
            spacing: 4

            Text {
                text: root.muted ? "󰝟" : "󰕾"
                color: root.muted ? theme.rose : (root.hovered ? theme.bright : theme.purple)
                font.pixelSize: theme.barFontSize
                font.family: theme.fontFamily
                font.weight: Font.Bold

                Behavior on color { ColorAnimation { duration: theme.transitionDuration } }
            }
            Text {
                visible: !root.muted
                text: root.pct.toString().padStart(2, " ") + "%"
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
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: Quickshell.execDetached(["pavucontrol"])
        onWheel: wheel => {
            Quickshell.execDetached(["qs", "ipc", "call", "osd", "volume", wheel.angleDelta.y > 0 ? "raise" : "lower"])
        }
    }
}
