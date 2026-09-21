import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../"

// content only - the surface behind the whole stack is one BlobRect owned by
// the bar, so a card never carries a blob of its own
Item {
    id: root

    required property var notification
    signal dismissed

    readonly property Theme theme: Theme {}
    readonly property bool critical: notification && notification.urgency === NotificationUrgency.Critical

    readonly property int cardPad: 12
    readonly property real fullHeight: content.implicitHeight + cardPad * 2

    property bool revealed: false
    property real growth: revealed ? 1 : 0

    implicitWidth: theme.toastWidth
    implicitHeight: Math.max(0, fullHeight * growth)

    // the card unrolls rather than sliding, so the panel it sits in grows by
    // exactly the amount the card reveals
    clip: true

    Behavior on growth {
        NumberAnimation {
            duration: root.theme.spatialDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.theme.easingSpatial
        }
    }

    Component.onCompleted: revealed = true

    function requestDismiss(): void {
        root.revealed = false;
        dismissTimer.restart();
    }

    Timer {
        id: dismissTimer

        interval: root.theme.spatialDuration
        onTriggered: root.dismissed()
    }

    Timer {
        running: root.notification && root.notification.urgency !== NotificationUrgency.Critical
        interval: root.notification && root.notification.urgency === NotificationUrgency.Low ? 3000 : 5000
        onTriggered: root.requestDismiss()
    }

    Connections {
        target: root.notification

        function onClosed(): void {
            dismissTimer.stop();
            root.dismissed();
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.requestDismiss()
    }

    Column {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.cardPad
        spacing: 6
        opacity: Math.max(0, Math.min(1, (root.growth - 0.3) / 0.5))

        Row {
            width: parent.width
            spacing: 8

            Image {
                id: icon

                width: 22
                height: 22
                visible: source != ""
                fillMode: Image.PreserveAspectFit
                source: {
                    if (!root.notification)
                        return "";
                    if (root.notification.image)
                        return root.notification.image;
                    if (root.notification.appIcon)
                        return Quickshell.iconPath(root.notification.appIcon, true);
                    return "";
                }
            }

            Text {
                width: parent.width - (icon.visible ? icon.width + 8 : 0)
                text: root.notification ? root.notification.appName || root.notification.summary : ""
                color: root.theme.dim
                font.pixelSize: 11
                font.family: root.theme.fontFamily
                font.weight: Font.Normal
                elide: Text.ElideRight
            }
        }

        Text {
            width: parent.width
            text: root.notification ? root.notification.summary : ""
            visible: text !== ""
            color: root.critical ? root.theme.rose : root.theme.bright
            font.pixelSize: 13
            font.bold: true
            font.family: root.theme.fontFamily
            font.weight: Font.Normal
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.notification ? root.notification.body : ""
            visible: text !== ""
            color: root.theme.text
            font.pixelSize: 12
            font.family: root.theme.fontFamily
            font.weight: Font.Normal
            wrapMode: Text.WordWrap
            maximumLineCount: 4
            elide: Text.ElideRight
        }
    }
}
