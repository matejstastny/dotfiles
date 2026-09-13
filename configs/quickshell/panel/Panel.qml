import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../"
import "../common"

PopupWindow {
    id: root
    popoutName: "panel"
    keyboardFocusMode: "onDemand"
    centered: true
    popupWidth: 780
    popupHeight: 640

    property bool dndEnabled: false
    property bool caffeinateEnabled: false
    property bool kbdBacklightEnabled: true
    property bool typingSoundEnabled: false
    property var notifications
    signal toggleDnd()
    signal toggleCaffeinate()
    signal toggleKbdBacklight()
    signal toggleTypingSound()
    signal openBluetooth()
    signal clearAll()
    signal dismissNotification(var notification)

    property int notifCount: notifications ? notifications.values.length : 0
    Connections {
        target: root.notifications
        function onValuesChanged() {
            root.notifCount = root.notifications.values.length
        }
    }

    readonly property int columnGap: 24

    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: 1
        color: theme.muted
        opacity: 0.5
    }

    Item {
        id: leftColumn
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: (parent.width - root.columnGap) / 2
        focus: root.open
        Keys.onEscapePressed: root.closeRequested()

        Item {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
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
                anchors.right: parent.right
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
        }

        Row {
            id: toggles
            anchors.top: header.bottom
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 10

            readonly property int toggleWidth: (width - spacing * 4) / 5

            QuickToggle {
                icon: "󰂛"
                width: toggles.toggleWidth
                height: width
                checked: root.dndEnabled
                onToggled: root.toggleDnd()
            }
            QuickToggle {
                icon: "󰅶"
                width: toggles.toggleWidth
                height: width
                checked: root.caffeinateEnabled
                onToggled: root.toggleCaffeinate()
            }
            QuickToggle {
                icon: "󰌌"
                width: toggles.toggleWidth
                height: width
                checked: root.kbdBacklightEnabled
                onToggled: root.toggleKbdBacklight()
            }
            QuickToggle {
                icon: "󰏩"
                width: toggles.toggleWidth
                height: width
                checked: root.typingSoundEnabled
                onToggled: root.toggleTypingSound()
            }
            QuickToggle {
                icon: "󰂯"
                width: toggles.toggleWidth
                height: width
                onToggled: root.openBluetooth()
            }
        }

        Calendar {
            id: calendar
            anchors.top: toggles.bottom
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.right: parent.right
        }

        Column {
            id: mediaColumn
            anchors.top: calendar.bottom
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.right: parent.right
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
    }

    Item {
        id: rightColumn
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: (parent.width - root.columnGap) / 2

        Item {
            id: notifHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 18

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "notifications" + (root.notifCount > 0 ? " · " + root.notifCount : "")
                color: theme.purple
                font.pixelSize: 13
                font.bold: true
                font.family: theme.fontFamily
                font.weight: Font.Normal
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

        ListView {
            id: list
            anchors.top: notifHeader.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
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
