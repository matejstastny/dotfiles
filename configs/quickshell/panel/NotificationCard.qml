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
    property bool expanded: false
    signal dismissed()

    readonly property bool critical: notification && notification.urgency === NotificationUrgency.Critical
    readonly property bool expandable: notification && ((notification.body && notification.body.length > 0) || (notification.actions && notification.actions.length > 0))
    readonly property real dismissThreshold: 0.4
    property real dragX: 0
    property bool revealed: false

    implicitHeight: content.implicitHeight + 24
    color: Theme.surface
    borderWidth: Theme.borderWidth
    borderColor: critical ? Theme.rose : Theme.muted
    opacity: 1 - Math.min(1, Math.abs(dragX) / (width * dismissThreshold)) * 0.7
    transformOrigin: Item.TopRight
    scale: revealed ? 1 : 0.1
    radius: revealed ? Theme.radius : Math.max(width, height)
    transform: Translate { x: root.dragX }

    function requestDismiss() {
        root.revealed = false
        dismissTimer.start()
    }

    Component.onCompleted: revealed = true

    Behavior on scale {
        NumberAnimation { duration: Theme.spatialDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easingSpatial }
    }
    Behavior on dragX {
        enabled: !dragArea.pressed
        NumberAnimation { duration: Theme.spatialDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easingSpatial }
    }

    Timer {
        id: dismissTimer
        interval: Theme.spatialDuration
        onTriggered: root.dismissed()
    }

    Timer {
        id: flyOffTimer
        interval: Theme.spatialDuration
        onTriggered: root.dismissed()
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        property real pressX: 0

        onPressed: mouse => pressX = mouse.x
        onPositionChanged: mouse => {
            if (pressed)
                root.dragX = mouse.x - pressX
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
            if (Math.abs(root.dragX) >= 4)
                return
            if (root.expandable && !root.expanded)
                root.expanded = true
            else if (root.dismissOnClick || root.expanded || !root.expandable)
                root.requestDismiss()
        }
    }

    Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 7

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
                        if (!notification) return ""
                        if (notification.image) return notification.image
                        if (notification.appIcon) return Quickshell.iconPath(notification.appIcon, true)
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
                        text: notification ? (notification.appName || notification.summary) + "  •  now" : ""
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
                    text: notification ? notification.summary : ""
                    visible: text !== ""
                    color: Theme.bright
                    font.pixelSize: Theme.sizeBody
                    font.family: Theme.fontMono
                    font.weight: Theme.weightHeading
                    wrapMode: Text.WordWrap
                    maximumLineCount: root.expanded ? 2 : 1
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: notification ? notification.body : ""
                    visible: text !== ""
                    color: Theme.text
                    font.pixelSize: Theme.sizeLabel
                    font.family: Theme.fontMono
                    font.weight: Theme.weightBody
                    wrapMode: Text.WordWrap
                    maximumLineCount: root.expanded ? (root.compact ? 4 : 6) : 1
                    elide: Text.ElideRight
                }
            }
        }

        Row {
            width: parent.width
            spacing: 6
            visible: root.expanded && !compact && notification && notification.actions && notification.actions.length > 0

            Repeater {
                model: notification ? notification.actions : []
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
