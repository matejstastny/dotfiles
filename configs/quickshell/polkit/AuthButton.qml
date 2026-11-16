import QtQuick
import "../"
import "../common"

FocusScope {
    id: root

    property string label: ""
    property bool primary: false
    property bool selected: false
    property bool danger: false

    signal clicked

    implicitWidth: labelText.implicitWidth + Theme.paddingLarge * 2
    implicitHeight: 38
    activeFocusOnTab: true

    function trigger(): void {
        if (root.enabled)
            root.clicked();
    }

    Keys.onReturnPressed: root.trigger()
    Keys.onEnterPressed: root.trigger()
    Keys.onSpacePressed: root.trigger()

    SquircleRect {
        anchors.fill: parent
        radius: pointer.pressed ? Theme.radiusPressed : (root.activeFocus || root.selected ? Theme.radiusActive : Theme.radiusRest)
        color: {
            if (root.primary)
                return root.enabled ? Theme.purple : Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.16);
            if (root.selected)
                return Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.16);
            return Theme.overlay;
        }
        borderWidth: Theme.borderWidth
        borderColor: {
            if (root.activeFocus || pointer.containsMouse)
                return root.danger ? Theme.rose : Theme.purple;
            if (root.selected)
                return Theme.purple;
            return Theme.muted;
        }

        Text {
            id: labelText

            anchors.centerIn: parent
            text: root.label
            color: !root.enabled ? Theme.dim : (root.primary ? Theme.bright : (root.danger ? Theme.rose : Theme.text))
            font.family: Theme.fontSans
            font.pixelSize: Theme.sizeBody
            font.weight: root.primary || root.selected ? Theme.weightMedium : Theme.weightBody
        }
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: root.forceActiveFocus()
        onClicked: root.trigger()
    }

    opacity: root.enabled ? 1 : 0.7
    scale: pointer.pressed ? 0.97 : 1

    Behavior on scale {
        NumberAnimation {
            duration: Theme.snapDuration
            easing.type: Easing.OutCubic
        }
    }
}
