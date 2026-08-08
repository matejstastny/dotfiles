import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import "../"
import "../common"

PanelWindow {
    id: root

    property bool open: false
    property bool dndEnabled: false
    property bool caffeinateEnabled: false
    property var notifications
    signal toggleDnd()
    signal toggleCaffeinate()
    signal clearAll()
    signal dismissNotification(var notification)
    signal closeRequested()

    readonly property Theme theme: Theme {}

    property int notifCount: notifications ? notifications.values.length : 0
    Connections {
        target: root.notifications
        function onValuesChanged() {
            root.notifCount = root.notifications.values.length
        }
    }

    readonly property int shadowPad: 56

    visible: open
    color: "transparent"
    implicitWidth: 420 + shadowPad * 2
    implicitHeight: 700 + shadowPad * 2
    exclusiveZone: 0

    mask: Region { x: card.x; y: card.y; width: card.width; height: card.height }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:panel"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    focusable: false

    HyprlandFocusGrab {
        active: root.open
        windows: [QsWindow.window]
        onCleared: { console.log("DEBUG focusgrab cleared"); root.closeRequested() }
    }

    onOpenChanged: {
        if (open) PopoutState.current = "panel"
        else if (PopoutState.current === "panel") PopoutState.current = ""
    }
    Connections {
        target: PopoutState
        function onCurrentChanged() {
            if (PopoutState.current !== "panel" && root.open) root.closeRequested()
        }
    }

    anchors {
        top: true
        right: true
    }
    margins {
        top: 10 - shadowPad
        right: 10 - shadowPad
    }

    Rectangle {
        id: card
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: shadowPad
        width: 420
        height: 700
        radius: theme.radius
        color: theme.base
        focus: root.open
        Keys.onEscapePressed: root.closeRequested()
        border.width: theme.borderWidth
        border.color: theme.muted

        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: theme.transitionDuration; easing.type: Easing.OutCubic } }

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

        transform: Scale {
            origin.x: card.width
            origin.y: 0
            xScale: root.open ? 1 : 0.35
            yScale: root.open ? 1 : 0.1
            Behavior on xScale { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }
            Behavior on yScale { NumberAnimation { duration: 360; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        }

        Item {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            height: avatar.height

            Avatar {
                id: avatar
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                size: 40
                source: "file://" + Quickshell.env("HOME") + "/pictures/pfp.JPEG"
            }

            Column {
                anchors.left: avatar.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: clearText.left
                anchors.rightMargin: 10
                spacing: 2

                Text {
                    text: {
                        const h = new Date().getHours()
                        const greeting = h < 5 ? "still up" : h < 12 ? "good morning" : h < 18 ? "good afternoon" : h < 23 ? "good evening" : "good night"
                        return greeting + " ✦"
                    }
                    color: theme.purple
                    font.pixelSize: 15
                    font.bold: true
                    font.family: theme.fontFamily
                    font.weight: Font.Normal
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: Quickshell.env("USER")
                    color: theme.dim
                    font.pixelSize: 11
                    font.family: theme.fontFamily
                    font.weight: Font.Normal
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            Text {
                id: clearText
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "clear ✧"
                color: clearArea.pressed ? theme.purple : theme.dim
                font.pixelSize: 11
                font.family: theme.fontFamily
                font.weight: Font.Normal
                scale: clearArea.pressed ? 0.92 : 1

                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: clearArea
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.clearAll()
                }
            }
        }

        Row {
            id: toggles
            anchors.top: header.bottom
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            spacing: 10

            ToggleSwitch {
                width: (parent.width - 10) / 2
                label: "do not disturb"
                icon: "󰂛"
                checked: root.dndEnabled
                onToggled: root.toggleDnd()
            }
            ToggleSwitch {
                width: (parent.width - 10) / 2
                label: "caffeinate"
                icon: "󰅶"
                checked: root.caffeinateEnabled
                onToggled: root.toggleCaffeinate()
            }
        }

        Column {
            id: mediaColumn
            anchors.top: toggles.bottom
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            spacing: 10

            Repeater {
                model: Mpris.players.values
                delegate: MediaCard {
                    required property var modelData
                    width: mediaColumn.width
                    visible: modelData.playbackState !== MprisPlaybackState.Stopped
                    player: modelData
                }
            }
        }

        ListView {
            id: list
            anchors.top: mediaColumn.bottom
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 16
            clip: true
            spacing: 10
            model: root.notifications
            boundsBehavior: Flickable.StopAtBounds

            delegate: NotificationCard {
                id: notifDelegate
                required property var modelData
                width: list.width
                compact: false
                notification: modelData
                onDismissed: root.dismissNotification(modelData)

                ListView.onRemove: removeAnimation.start()

                SequentialAnimation {
                    id: removeAnimation
                    PropertyAction { target: notifDelegate; property: "ListView.delayRemove"; value: true }
                    ParallelAnimation {
                        NumberAnimation { target: notifDelegate; property: "opacity"; to: 0; duration: 160; easing.type: Easing.OutCubic }
                        NumberAnimation { target: notifDelegate; property: "scale"; to: 0.9; duration: 160; easing.type: Easing.OutCubic }
                    }
                    PropertyAction { target: notifDelegate; property: "ListView.delayRemove"; value: false }
                }
            }

            displaced: Transition {
                NumberAnimation { properties: "y"; duration: 180; easing.type: Easing.OutCubic }
            }

            Text {
                anchors.centerIn: parent
                visible: root.notifCount === 0
                text: "nothing here ✧"
                color: theme.dim
                font.pixelSize: 12
                font.family: theme.fontFamily
                font.weight: Font.Normal
            }
        }
    }
}
