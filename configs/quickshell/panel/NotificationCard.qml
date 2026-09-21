import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../"
import "../common"

SquircleRect {
    id: root

    property var notification
    property bool compact: false
    property bool dismissOnClick: false
    signal dismissed()

    readonly property bool critical: notification && notification.urgency === NotificationUrgency.Critical

    implicitHeight: content.implicitHeight + 24
    color: theme.surface
    borderWidth: theme.borderWidth
    borderColor: critical ? theme.rose : theme.muted

    readonly property real dismissThreshold: 0.4
    property real dragX: 0
    opacity: 1 - Math.min(1, Math.abs(dragX) / (width * dismissThreshold)) * 0.7

    // appears/retreats as a shrinking blob anchored at the top-right corner -
    // the corner closest to the bar it "came from" - instead of a flat fade,
    // so it visually pinches down to a point rather than just vanishing
    property bool revealed: false
    transformOrigin: Item.TopRight
    scale: revealed ? 1 : 0.1
    radius: revealed ? theme.radius : Math.max(width, height)

    Behavior on scale {
        NumberAnimation { duration: theme.spatialDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: theme.easingSpatial }
    }

    function requestDismiss() {
        root.revealed = false
        dismissTimer.start()
    }

    Component.onCompleted: revealed = true

    transform: Translate { x: root.dragX }

    Behavior on dragX {
        enabled: !dragArea.pressed
        NumberAnimation { duration: theme.spatialDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: theme.easingSpatial }
    }

    Timer {
        id: dismissTimer
        interval: theme.spatialDuration
        onTriggered: root.dismissed()
    }

    Timer {
        id: flyOffTimer
        interval: theme.spatialDuration
        onTriggered: root.dismissed()
    }

    // declared first so it sits behind the close button / action buttons,
    // which still take priority for their own smaller hit areas
    MouseArea {
        id: dragArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        property real pressX: 0

        onPressed: mouse => pressX = mouse.x
        onPositionChanged: mouse => {
            if (pressed) root.dragX = mouse.x - pressX
        }
        onReleased: {
            if (Math.abs(root.dragX) > root.width * root.dismissThreshold) {
                root.dragX = root.width * (root.dragX > 0 ? 1.2 : -1.2)
                flyOffTimer.start()
            } else {
                root.dragX = 0
            }
        }
        onClicked: {
            if (root.dismissOnClick && Math.abs(root.dragX) < 4) root.requestDismiss()
        }
    }

    Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 6

        Row {
            width: parent.width
            spacing: 8

            Image {
                id: icon
                width: 22
                height: 22
                visible: source != ""
                source: {
                    if (!notification) return ""
                    if (notification.image) return notification.image
                    if (notification.appIcon) return Quickshell.iconPath(notification.appIcon, true)
                    return ""
                }
                fillMode: Image.PreserveAspectFit
            }

            Text {
                width: parent.width - (icon.visible ? icon.width + 8 : 0) - closeBtn.width - 8
                text: notification ? notification.appName || notification.summary : ""
                color: theme.dim
                font.pixelSize: 11
                font.family: theme.fontFamily
                font.weight: Font.Normal
                elide: Text.ElideRight
            }

            Text {
                id: closeBtn
                text: ""
                color: theme.dim
                font.pixelSize: 12
                font.family: theme.fontFamily
                font.weight: Font.Normal

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.dismissed()
                }
            }
        }

        Text {
            width: parent.width
            text: notification ? notification.summary : ""
            visible: text !== ""
            color: theme.bright
            font.pixelSize: 13
            font.bold: true
            font.family: theme.fontFamily
            font.weight: Font.Normal
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: notification ? notification.body : ""
            visible: text !== ""
            color: theme.text
            font.pixelSize: 12
            font.family: theme.fontFamily
            font.weight: Font.Normal
            wrapMode: Text.WordWrap
            maximumLineCount: compact ? 4 : 2
            elide: Text.ElideRight
        }

        Row {
            width: parent.width
            spacing: 6
            // action buttons (e.g. "View") mostly just try to focus the
            // originating app, which does nothing useful without
            // Hyprland's autofocus - not worth the clutter on toasts
            visible: !compact && notification && notification.actions && notification.actions.length > 0

            Repeater {
                model: notification ? notification.actions : []
                delegate: Rectangle {
                    required property var modelData
                    height: 26
                    width: actionLabel.implicitWidth + 16
                    radius: theme.radiusSmall
                    color: theme.overlay
                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: modelData.text
                        color: theme.text
                        font.pixelSize: 11
                        font.family: theme.fontFamily
                        font.weight: Font.Normal
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
