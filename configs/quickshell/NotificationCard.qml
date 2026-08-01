import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Rectangle {
    id: root

    property var notification
    property bool compact: false
    signal dismissed()

    readonly property Theme theme: Theme {}
    readonly property bool critical: notification && notification.urgency === NotificationUrgency.Critical

    implicitHeight: content.implicitHeight + 24
    radius: theme.radius
    color: theme.surface
    border.width: 1
    border.color: critical ? theme.rose : theme.muted

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
                elide: Text.ElideRight
            }

            Text {
                id: closeBtn
                text: ""
                color: theme.dim
                font.pixelSize: 12
                font.family: theme.fontFamily

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
            wrapMode: Text.WordWrap
            maximumLineCount: compact ? 4 : 2
            elide: Text.ElideRight
        }

        Row {
            width: parent.width
            spacing: 6
            visible: notification && notification.actions && notification.actions.length > 0

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
