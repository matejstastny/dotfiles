import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"

PanelWindow {
    id: root

    readonly property Theme theme: Theme {}
    readonly property int barCount: 80
    readonly property int barGap: 4
    readonly property int barMaxHeight: 200
    readonly property real barOpacity: 0.9

    property bool open: false
    property var barValues: []

    readonly property real barSlot: width / barCount

    function barColor(idx) {
        const t = root.barCount > 1 ? idx / (root.barCount - 1) : 0
        return Qt.rgba(
            theme.purple.r + (theme.rose.r - theme.purple.r) * t,
            theme.purple.g + (theme.rose.g - theme.purple.g) * t,
            theme.purple.b + (theme.rose.b - theme.purple.b) * t,
            root.barOpacity
        )
    }

    visible: root.open
    color: "transparent"
    implicitHeight: barMaxHeight
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:cava"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    focusable: false

    anchors {
        bottom: true
        left: true
        right: true
    }
    margins.bottom: 0

    mask: Region {}

    Process {
        id: cavaProc
        running: root.open
        command: ["cava"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.split(";").filter(p => p.length > 0).map(Number)
                if (parts.length) root.barValues = parts
            }
        }
    }

    onOpenChanged: if (!root.open) root.barValues = []

    Item {
        id: content
        anchors.fill: parent
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: theme.transitionDuration; easing.type: Easing.OutCubic } }

        Repeater {
            model: root.barCount

            Rectangle {
                id: bar
                required property int index
                readonly property real pct: index < root.barValues.length ? root.barValues[index] / 100 : 0

                x: index * root.barSlot
                width: Math.max(2, root.barSlot - root.barGap)
                height: Math.max(3, root.barMaxHeight * pct)
                anchors.bottom: parent.bottom
                topLeftRadius: width / 2
                topRightRadius: width / 2
                color: root.barColor(index)

                Behavior on height { NumberAnimation { duration: 30; easing.type: Easing.OutQuad } }
            }
        }
    }
}
