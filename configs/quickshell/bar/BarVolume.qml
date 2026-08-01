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

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    implicitWidth: label.implicitWidth + 8
    implicitHeight: 38

    Text {
        id: label
        anchors.centerIn: parent
        text: root.muted ? "󰝟" : "󰕾 " + root.pct + "%"
        color: theme.text
        font.pixelSize: 15
        font.family: theme.fontFamily
        font.weight: Font.Normal
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: Quickshell.execDetached(["pavucontrol"])
        onWheel: wheel => {
            Quickshell.execDetached(["swayosd-client", "--output-volume", wheel.angleDelta.y > 0 ? "raise" : "lower"])
        }
    }
}
