import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../"

Item {
    id: root

    required property var notification
    signal dismissed()

    readonly property bool critical: notification && notification.urgency === NotificationUrgency.Critical
    readonly property bool expandable: notification && ((notification.body && notification.body.length > 0) || (notification.actions && notification.actions.length > 0))
    readonly property int cardPad: 12
    readonly property real fullHeight: content.implicitHeight + cardPad * 2
    property bool expanded: false
    property bool revealed: false
    property real growth: revealed ? 1 : 0

    implicitWidth: Theme.toastWidth
    implicitHeight: Math.max(0, fullHeight * growth)
    clip: true

    Behavior on growth {
        NumberAnimation {
            duration: Theme.spatialDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.easingSpatial
        }
    }

    Component.onCompleted: revealed = true

    function requestDismiss(): void {
        root.revealed = false
        dismissTimer.restart()
    }

    Timer {
        id: dismissTimer
        interval: Theme.spatialDuration
        onTriggered: root.dismissed()
    }

    Timer {
        running: !root.expanded && root.notification && root.notification.urgency !== NotificationUrgency.Critical
        interval: root.notification && root.notification.urgency === NotificationUrgency.Low ? 3000 : 5000
        onTriggered: root.requestDismiss()
    }

    Connections {
        target: root.notification
        function onClosed(): void {
            dismissTimer.stop()
            root.dismissed()
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.expandable && !root.expanded)
                root.expanded = true
            else
                root.requestDismiss()
        }
    }

    Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.cardPad
        spacing: 7
        opacity: Math.max(0, Math.min(1, (root.growth - 0.3) / 0.5))

        Row {
            width: parent.width
            spacing: 10

            Item {
                id: icon
                width: 42
                height: 42

                Image {
                    id: imageIcon
                    anchors.fill: parent
                    source: {
                        if (!root.notification) return ""
                        if (root.notification.image) return root.notification.image
                        if (root.notification.appIcon) return Quickshell.iconPath(root.notification.appIcon, true)
                        return ""
                    }
                    visible: status === Image.Ready
                    fillMode: Image.PreserveAspectFit
                }

                Rectangle {
                    anchors.fill: parent
                    visible: !imageIcon.visible
                    radius: width / 2
                    color: root.critical ? Qt.rgba(Theme.rose.r, Theme.rose.g, Theme.rose.b, 0.22) : Theme.overlay

                    Text {
                        anchors.centerIn: parent
                        text: "✦"
                        color: root.critical ? Theme.rose : Theme.purple
                        font.pixelSize: 22
                        font.family: Theme.fontMono
                    }
                }
            }

            Column {
                width: parent.width - icon.width - parent.spacing
                spacing: 2

                Row {
                    width: parent.width

                    Text {
                        width: parent.width - expandGlyph.width - 8
                        text: root.notification ? (root.notification.appName || root.notification.summary) + "  •  now" : ""
                        color: Theme.dim
                        font.pixelSize: Theme.sizeLabel
                        font.family: Theme.fontMono
                        elide: Text.ElideRight
                    }

                    Text {
                        id: expandGlyph
                        visible: root.expandable
                        text: root.expanded ? "⌃" : "⌄"
                        color: Theme.dim
                        font.pixelSize: Theme.sizeLabel
                        font.family: Theme.fontMono
                    }
                }

                Text {
                    width: parent.width
                    text: root.notification ? root.notification.summary : ""
                    visible: text !== ""
                    color: root.critical ? Theme.rose : Theme.bright
                    font.pixelSize: Theme.sizeBody
                    font.family: Theme.fontMono
                    font.weight: Theme.weightHeading
                    wrapMode: Text.WordWrap
                    maximumLineCount: root.expanded ? 2 : 1
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.notification ? root.notification.body : ""
                    visible: text !== ""
                    color: Theme.text
                    font.pixelSize: Theme.sizeLabel
                    font.family: Theme.fontMono
                    wrapMode: Text.WordWrap
                    maximumLineCount: root.expanded ? 6 : 1
                    elide: Text.ElideRight
                }
            }
        }

        Row {
            width: parent.width
            spacing: 6
            visible: root.expanded && root.notification && root.notification.actions && root.notification.actions.length > 0

            Repeater {
                model: root.notification ? root.notification.actions : []
                delegate: Rectangle {
                    required property var modelData
                    height: 26
                    width: actionLabel.implicitWidth + 16
                    radius: Theme.radiusSmall
                    color: Theme.overlay

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: modelData.text
                        color: Theme.text
                        font.pixelSize: Theme.sizeLabel
                        font.family: Theme.fontMono
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.invoke()
                    }
                }
            }
        }
    }
}
