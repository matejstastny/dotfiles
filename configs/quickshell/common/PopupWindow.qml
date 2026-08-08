import QtQuick
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

    readonly property Theme theme: Theme {}

    default property alias content: contentArea.data

    visible: root.open
    color: "transparent"
    exclusiveZone: 0

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
        top: root.centered ? 0 : 10
        right: root.centered ? 0 : 10
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: theme.radius
        color: theme.base
        border.width: theme.borderWidth
        border.color: theme.muted

        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: theme.transitionDuration; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: theme.transitionDuration; easing.type: Easing.OutCubic } }

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
