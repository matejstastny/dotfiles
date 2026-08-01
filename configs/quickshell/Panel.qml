import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

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
    // never grabs keyboard/pointer focus - dismissal on outside click is
    // driven externally (shell.qml watches Hyprland's active window instead
    // of us stealing focus), so real apps never lose focus to this popup
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    focusable: false

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
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "clear ✧"
                color: theme.dim
                font.pixelSize: 11
                font.family: theme.fontFamily
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
            }
        }
    }
}
