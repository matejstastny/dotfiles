import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import "../"

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

    // NotificationServer's trackedNotifications is exposed as `property var`,
    // and QML's implicit binding dependency tracking doesn't reliably follow
    // through var -> .values.length chains, so count it explicitly instead.
    property int notifCount: notifications ? notifications.values.length : 0
    Connections {
        target: root.notifications
        function onValuesChanged() {
            root.notifCount = root.notifications.values.length
        }
    }

    visible: open
    color: "transparent"
    implicitWidth: 420
    implicitHeight: 700
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:panel"
    // keyboardFocus only flips to OnDemand while the grab below is active,
    // so real apps never lose focus just because this window exists
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    focusable: false

    // HyprlandFocusGrab is Hyprland's own mechanism for "dismiss this popup
    // when the user interacts elsewhere" - unlike a MouseArea scrim, the
    // click that dismisses it is delivered normally to whatever's underneath
    // instead of being swallowed by us
    HyprlandFocusGrab {
        active: root.open
        windows: [QsWindow.window]
        onCleared: root.closeRequested()
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
        top: 10
        right: 10
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: theme.radius
        color: theme.base
        border.width: 1
        border.color: theme.muted

        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        Item {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            height: titleText.implicitHeight

            Text {
                id: titleText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "✦ control centre"
                color: theme.purple
                font.pixelSize: 15
                font.bold: true
                font.family: theme.fontFamily
                font.weight: Font.Normal
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "clear ✧"
                color: theme.dim
                font.pixelSize: 11
                font.family: theme.fontFamily
                font.weight: Font.Normal
                MouseArea {
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
                required property var modelData
                width: list.width
                compact: false
                notification: modelData
                onDismissed: root.dismissNotification(modelData)
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
