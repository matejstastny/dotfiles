import QtQuick
import "../"

// outlined, the way it was. sized down from the 148px squares the old
// half-panel split produced, but the border stays - it is what makes these
// read as five switches rather than five glyphs
Rectangle {
    id: root

    property string icon: ""
    property bool checked: false
    signal toggled()

    implicitWidth: 56
    implicitHeight: 46
    height: implicitHeight

    radius: Theme.radiusSmall
    color: root.checked ? Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.18) : Theme.surface
    border.width: Theme.borderWidth
    border.color: !root.enabled ? Theme.muted : (mouseArea.containsMouse || root.checked ? Theme.purple : Theme.muted)
    opacity: root.enabled ? 1 : 0.4

    Behavior on color {
        ColorAnimation {
            duration: Theme.effectsDuration
        }
    }
    Behavior on border.color {
        ColorAnimation {
            duration: Theme.snapDuration
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.checked ? Theme.bright : Theme.dim
        font.pixelSize: Theme.iconLarge
        font.family: Theme.fontMono

        Behavior on color {
            ColorAnimation {
                duration: Theme.snapDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }

    scale: mouseArea.pressed ? 0.93 : (mouseArea.containsMouse ? 1.03 : 1)

    Behavior on scale {
        NumberAnimation {
            duration: Theme.snapDuration
            easing.type: Easing.OutCubic
        }
    }
}
