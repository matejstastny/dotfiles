import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../"

PanelWindow {
    id: root

    property bool open: false
    signal closeRequested()

    required property string popoutName
    property bool centered: true
    property string keyboardFocusMode: "exclusive"
    property string title: ""
    property int popupWidth: 400
    property int popupHeight: 400

    readonly property Theme theme: Theme {}
    readonly property int shadowPad: 56

    default property alias content: contentArea.data

    visible: root.open
    color: "transparent"
    implicitWidth: popupWidth + shadowPad * 2
    implicitHeight: popupHeight + shadowPad * 2
    exclusiveZone: 0

    mask: Region { item: card }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:" + root.popoutName
    WlrLayershell.keyboardFocus: root.open
        ? (root.keyboardFocusMode === "exclusive" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand)
        : WlrKeyboardFocus.None
    focusable: false

    HyprlandFocusGrab {
        active: root.open
        windows: [QsWindow.window]
        onCleared: root.closeRequested()
    }

    onOpenChanged: {
        if (root.open) PopoutState.current = root.popoutName
        else if (PopoutState.current === root.popoutName) PopoutState.current = ""
    }
    Connections {
        target: PopoutState
        function onCurrentChanged() {
            if (PopoutState.current !== root.popoutName && root.open) root.closeRequested()
        }
    }

    anchors {
        top: !root.centered
        right: !root.centered
    }
    margins {
        top: root.centered ? 0 : 10 - shadowPad
        right: root.centered ? 0 : 10 - shadowPad
    }

    Rectangle {
        id: card
        anchors.centerIn: root.centered ? parent : undefined
        anchors.top: root.centered ? undefined : parent.top
        anchors.right: root.centered ? undefined : parent.right
        anchors.margins: root.centered ? 0 : shadowPad
        width: root.popupWidth
        height: root.popupHeight
        radius: theme.radius
        color: theme.base
        border.width: theme.borderWidth
        border.color: theme.muted

        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: theme.transitionDuration; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: theme.popDuration; easing.type: Easing.OutBack; easing.overshoot: theme.popOvershoot } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "black"
            blurMax: 40
            shadowBlur: 1.0
            shadowVerticalOffset: 10
            shadowHorizontalOffset: 0
            shadowOpacity: 0.55
        }

        Item {
            id: header
            visible: root.title.length > 0
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            height: visible ? 18 : 0

            Text {
                id: titleText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "✦ " + root.title
                color: theme.purple
                font.pixelSize: 15
                font.bold: true
                font.family: theme.fontFamily
                font.weight: Font.Normal
            }
        }

        Item {
            id: contentArea
            anchors.top: header.visible ? header.bottom : parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 16
            anchors.topMargin: header.visible ? 14 : 16
        }
    }
}
