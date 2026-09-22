import QtQuick
import "../"

Item {
    id: root

    property bool open: false
    property string kind: "volume"
    property int pct: 0
    property bool muted: false

    readonly property real level: Math.max(0, Math.min(1, root.pct / 100))
    readonly property color accent: root.muted ? Theme.muted : Theme.purple

    // the glyph carries the level too, so the readout can stay a bare number
    readonly property string glyph: {
        if (root.kind === "brightness")
            return root.pct > 66 ? "󰃠" : (root.pct > 33 ? "󰃟" : "󰃞");
        if (root.muted)
            return "󰝟";
        if (root.pct === 0)
            return "󰕿";
        return root.pct > 50 ? "󰕾" : "󰖀";
    }

    implicitWidth: 188
    implicitHeight: 24

    Text {
        id: icon

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 20
        horizontalAlignment: Text.AlignHCenter

        text: root.glyph
        color: root.muted ? Theme.rose : Theme.purple
        font.pixelSize: 15
        font.family: Theme.fontMono

        Behavior on color {
            ColorAnimation {
                duration: Theme.effectsDuration
            }
        }
    }

    Text {
        id: value

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        horizontalAlignment: Text.AlignRight

        text: root.pct
        color: root.muted ? Theme.dim : Theme.bright
        font.pixelSize: 11
        font.family: Theme.fontMono
        font.weight: Font.DemiBold

        Behavior on color {
            ColorAnimation {
                duration: Theme.effectsDuration
            }
        }
    }

    Rectangle {
        id: track

        anchors.left: icon.right
        anchors.leftMargin: 10
        anchors.right: value.left
        anchors.rightMargin: 9
        anchors.verticalCenter: parent.verticalCenter

        height: 4
        radius: height / 2
        color: Theme.overlay

        Rectangle {
            id: fill

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            radius: parent.radius
            width: Math.max(parent.radius * 2, parent.width * root.level)
            color: root.accent

            Behavior on width {
                NumberAnimation {
                    duration: Theme.spatialDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.easingDrawer
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Theme.effectsDuration
                }
            }
        }

        Rectangle {
            id: head

            width: 8
            height: 8
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(track.width - width, fill.width - width / 2))
            color: root.muted ? Theme.rose : Theme.bright

            Behavior on color {
                ColorAnimation {
                    duration: Theme.effectsDuration
                }
            }
        }
    }
}
