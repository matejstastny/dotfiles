import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../"
import "../common"

// content only - the surface under this is the drawer it sits in, drawn by the
// blob field along with the bar it hangs off.
//
// one surface, not a box of boxes. the old panel put a bordered card around the
// calendar, another around the media, five more around the toggles, and then
// sat all of that inside a bordered drawer. everything here is laid straight on
// the drawer and separated by space and hairlines instead, which is the same
// argument the blob field makes about the bar.
//
// the left rail is the answer to "what is going on right now" - the date, what
// is playing, the five switches. notifications are the only thing that is a
// list of discrete objects, so they are the only things that keep their cards,
// and they get a column that only exists when there is something in it
Item {
    id: root

    property bool open: false
    signal closeRequested()

    property bool dndEnabled: false
    property bool caffeinateEnabled: false
    property bool kbdBacklightEnabled: true
    property bool typingSoundEnabled: false
    property bool cavaEnabled: false
    property var notifications
    signal toggleDnd()
    signal toggleCaffeinate()
    signal toggleKbdBacklight()
    signal toggleTypingSound()
    signal toggleCava()
    signal clearAll()
    signal dismissNotification(var notification)

    property int notifCount: notifications ? notifications.values.length : 0
    property var notificationGroups: []

    // which app groups are open, by group key. rebuilding the group array on
    // every incoming notification used to reset this, so one new notification
    // collapsed everything you had expanded
    property var expandedGroups: ({})

    readonly property int railWidth: 320
    readonly property int notifWidth: 340
    readonly property int notifMaxHeight: 420
    readonly property bool hasNotifications: root.notifCount > 0

    // whoever is playing, else whoever is there. matches what the bar shows
    readonly property var player: {
        const players = Mpris.players.values;
        for (let i = 0; i < players.length; i++)
            if (players[i].isPlaying)
                return players[i];
        for (let i = 0; i < players.length; i++)
            if (players[i].playbackState !== MprisPlaybackState.Stopped)
                return players[i];
        return null;
    }

    implicitWidth: root.railWidth + Theme.paddingLarge * 2 + root.notifWidth
    implicitHeight: Math.max(rail.implicitHeight, notifColumn.implicitHeight)

    focus: root.open
    Keys.onEscapePressed: root.closeRequested()

    function rebuildNotificationGroups(): void {
        const groups = [];
        const byApp = {};
        const items = root.notifications ? root.notifications.values : [];
        for (const notification of items) {
            const key = notification.desktopEntry || notification.appName || "system";
            if (!byApp[key]) {
                byApp[key] = {
                    key,
                    appName: notification.appName || "system",
                    appIcon: notification.appIcon || "",
                    items: []
                };
                groups.push(byApp[key]);
            }
            byApp[key].items.push(notification);
        }
        root.notificationGroups = groups;
    }

    function groupExpanded(group: var): bool {
        // a group of one has nothing to expand into, so it is always open
        if (group.items.length === 1)
            return true;
        return root.expandedGroups[group.key] === true;
    }

    function toggleGroup(group: var): void {
        const next = Object.assign({}, root.expandedGroups);
        next[group.key] = !(next[group.key] === true);
        root.expandedGroups = next;
    }

    Connections {
        target: root.notifications
        function onValuesChanged() {
            root.notifCount = root.notifications.values.length;
            root.rebuildNotificationGroups();
        }
    }

    onNotificationsChanged: root.rebuildNotificationGroups()

    Column {
        id: rail

        anchors.top: parent.top
        anchors.left: parent.left
        width: root.railWidth
        spacing: Theme.gapLarge

        DateBlock {
            width: parent.width
            visible: root.open
        }

        Hairline {
            width: parent.width
        }

        // a Loader rather than a hidden item: with nothing playing there is no
        // player object to dereference, and bindings in an invisible item are
        // evaluated just the same
        Loader {
            id: media

            width: parent.width
            active: root.player !== null
            visible: media.active
            sourceComponent: nowPlaying
        }

        Hairline {
            width: parent.width
            visible: media.active
        }

        Row {
            id: toggles

            width: parent.width
            spacing: Theme.gapSmall

            readonly property int toggleWidth: (width - spacing * 4) / 5

            QuickToggle {
                icon: "󰂛"
                implicitWidth: toggles.toggleWidth
                checked: root.dndEnabled
                onToggled: root.toggleDnd()
            }
            QuickToggle {
                icon: "󰅶"
                implicitWidth: toggles.toggleWidth
                checked: root.caffeinateEnabled
                onToggled: root.toggleCaffeinate()
            }
            QuickToggle {
                icon: "󰌌"
                implicitWidth: toggles.toggleWidth
                checked: root.kbdBacklightEnabled
                onToggled: root.toggleKbdBacklight()
            }
            QuickToggle {
                icon: "󰏩"
                implicitWidth: toggles.toggleWidth
                checked: root.typingSoundEnabled
                onToggled: root.toggleTypingSound()
            }
            QuickToggle {
                icon: "󰎇"
                implicitWidth: toggles.toggleWidth
                checked: root.cavaEnabled
                onToggled: root.toggleCava()
            }
        }
    }

    // a vertical hairline rather than a column of its own width: the two halves
    // have no reason to be the same size, so nothing here is centred on a split
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: rail.right
        anchors.leftMargin: Theme.paddingLarge
        width: Theme.borderWidth
        color: Theme.muted
        opacity: 0.4
    }

    Item {
        id: notifColumn

        anchors.top: parent.top
        anchors.right: parent.right
        width: root.notifWidth
        implicitHeight: notifHeader.height + Theme.gap + Math.max(Theme.rowHeight, Math.min(root.notifMaxHeight, list.contentHeight))
        height: implicitHeight

        Item {
            id: notifHeader

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 18

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "✦ notifications · " + root.notifCount
                color: Theme.purple
                font.pixelSize: Theme.sizeBody
                font.family: Theme.fontMono
                font.weight: Theme.weightHeading
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: root.hasNotifications
                text: "clear all"
                color: clearArea.pressed ? Theme.rose : (clearArea.containsMouse ? Theme.bright : Theme.dim)
                font.pixelSize: Theme.sizeLabel
                font.family: Theme.fontMono
                scale: clearArea.pressed ? 0.94 : 1

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.snapDuration
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.snapDuration
                        easing.type: Easing.OutCubic
                    }
                }

                // "destroy everything" was an 11px word with a six pixel slop
                // around it and no hover state at all
                MouseArea {
                    id: clearArea
                    anchors.fill: parent
                    anchors.margins: -Theme.gap
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.clearAll()
                }
            }
        }

        ListView {
            id: list

            anchors.top: notifHeader.bottom
            anchors.topMargin: Theme.gap
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true
            spacing: Theme.gap
            model: root.notificationGroups
            boundsBehavior: Flickable.StopAtBounds

            delegate: Column {
                id: groupDelegate

                required property var modelData

                readonly property bool grouped: groupDelegate.modelData.items.length > 1
                readonly property bool expanded: root.groupExpanded(groupDelegate.modelData)

                width: list.width
                spacing: Theme.gapSmall

                Item {
                    width: parent.width
                    height: groupDelegate.grouped ? 22 : 0
                    visible: groupDelegate.grouped

                    Image {
                        id: groupIcon
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.iconSmall
                        height: Theme.iconSmall
                        visible: source !== ""
                        source: groupDelegate.modelData.appIcon ? Quickshell.iconPath(groupDelegate.modelData.appIcon, true) : ""
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        anchors.left: groupIcon.visible ? groupIcon.right : parent.left
                        anchors.leftMargin: groupIcon.visible ? Theme.gapSmall : 0
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: groupCount.left
                        anchors.rightMargin: Theme.gapSmall
                        text: groupDelegate.modelData.appName
                        color: groupHeaderArea.containsMouse ? Theme.bright : Theme.dim
                        font.pixelSize: Theme.sizeLabel
                        font.family: Theme.fontSans
                        font.weight: Theme.weightHeading
                        elide: Text.ElideRight

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.snapDuration
                            }
                        }
                    }

                    Text {
                        id: groupCount
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: groupDelegate.modelData.items.length + "  " + (groupDelegate.expanded ? "⌃" : "⌄")
                        color: Theme.muted
                        font.pixelSize: Theme.sizeMicro
                        font.family: Theme.fontMono
                    }

                    MouseArea {
                        id: groupHeaderArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleGroup(groupDelegate.modelData)
                    }
                }

                Repeater {
                    model: groupDelegate.expanded ? groupDelegate.modelData.items : []

                    delegate: NotificationCard {
                        required property var modelData
                        width: groupDelegate.width
                        compact: false
                        notification: modelData
                        onDismissed: root.dismissNotification(modelData)
                    }
                }
            }

            displaced: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: Theme.spatialDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.easingSpatial
                }
            }
        }

        Text {
            anchors.top: list.top
            anchors.topMargin: Theme.gapSmall
            anchors.left: parent.left
            visible: !root.hasNotifications
            text: "nothing here"
            color: Theme.muted
            font.pixelSize: Theme.sizeBody
            font.family: Theme.fontMono
        }
    }

    Component {
        id: nowPlaying

        NowPlaying {
            player: root.player
        }
    }

    component Hairline: Rectangle {
        height: Theme.borderWidth
        color: Theme.muted
        opacity: 0.4
    }
}
