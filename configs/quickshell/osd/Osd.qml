import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "../"

PanelWindow {
    id: root

    readonly property Theme theme: Theme {}
    readonly property int barHeight: 35
    readonly property int gap: 12
    readonly property int hideDelay: 1400
    readonly property real step: 0.05

    property bool shown: false
    property string kind: "volume"
    property int pct: 0
    property bool muted: false

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool sinkReady: sink && sink.audio

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    visible: root.shown
    color: "transparent"
    implicitWidth: 240
    implicitHeight: 68
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    focusable: false

    anchors.top: true
    margins.top: root.barHeight + root.gap

    IpcHandler {
        target: "osd"

        function volume(action: string): void {
            if (action === "raise") root.raiseVolume()
            else if (action === "lower") root.lowerVolume()
            else if (action === "mute-toggle") root.toggleMuteVolume()
        }

        function brightness(action: string): void {
            if (action === "raise") root.raiseBrightness()
            else if (action === "lower") root.lowerBrightness()
        }
    }

    Timer {
        id: hideTimer
        interval: root.hideDelay
        onTriggered: root.shown = false
    }

    function reveal() {
        root.shown = true
        hideTimer.restart()
    }

    function raiseVolume() {
        if (!root.sinkReady) return
        if (root.sink.audio.muted) root.sink.audio.muted = false
        root.sink.audio.volume = Math.min(1, root.sink.audio.volume + root.step)
        showVolumeState()
    }
    function lowerVolume() {
        if (!root.sinkReady) return
        root.sink.audio.volume = Math.max(0, root.sink.audio.volume - root.step)
        showVolumeState()
    }
    function toggleMuteVolume() {
        if (!root.sinkReady) return
        root.sink.audio.muted = !root.sink.audio.muted
        showVolumeState()
    }
    function showVolumeState() {
        root.kind = "volume"
        root.pct = root.sinkReady ? Math.round(root.sink.audio.volume * 100) : 0
        root.muted = root.sinkReady && root.sink.audio.muted
        root.reveal()
    }

    function raiseBrightness() {
        brightnessProc.command = ["brightnessctl", "-m", "set", "5%+"]
        brightnessProc.running = true
    }
    function lowerBrightness() {
        brightnessProc.command = ["brightnessctl", "-m", "set", "5%-"]
        brightnessProc.running = true
    }

    Process {
        id: brightnessProc
        stdout: SplitParser {
            onRead: data => {
                // machine-readable brightnessctl output: device,class,current,percent,max
                const pct = parseInt(data.trim().split(",")[3])
                if (isNaN(pct)) return
                root.kind = "brightness"
                root.pct = pct
                root.muted = false
                root.reveal()
            }
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: theme.radius
        color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.85)
        border.width: theme.borderWidth
        border.color: theme.muted

        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.94
        Behavior on opacity { NumberAnimation { duration: theme.transitionDuration; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: theme.popDuration; easing.type: Easing.OutBack; easing.overshoot: theme.popOvershoot } }

        Row {
            anchors.centerIn: parent
            spacing: 14

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.kind === "brightness" ? "󰃠" : (root.muted ? "󰝟" : "󰕾")
                color: root.muted ? theme.rose : theme.purple
                font.pixelSize: 20
                font.family: theme.fontFamily
                font.weight: Font.Bold
            }

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: 140
                height: 6
                radius: 3
                color: theme.overlay

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    radius: parent.radius
                    width: Math.max(radius * 2, parent.width * (root.muted ? 0 : Math.min(1, root.pct / 100)))
                    color: root.muted ? theme.rose : theme.purple

                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.pct.toString().padStart(3, " ") + "%"
                color: theme.dim
                font.pixelSize: 13
                font.family: theme.fontFamily
                font.weight: Font.Normal
            }
        }
    }
}
