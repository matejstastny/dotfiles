import QtQuick
import Quickshell.Services.Mpris
import "../"

Rectangle {
    id: root

    required property MprisPlayer player

    readonly property Theme theme: Theme {}

    implicitHeight: 74
    radius: theme.radius
    color: theme.surface
    border.width: theme.borderWidth
    border.color: theme.muted

    Image {
        id: art
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 10
        width: height
        visible: source != ""
        source: player.trackArtUrl || ""
        fillMode: Image.PreserveAspectCrop
        layer.enabled: true
    }

    Column {
        anchors.left: art.visible ? art.right : parent.left
        anchors.leftMargin: 12
        anchors.right: controls.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Text {
            width: parent.width
            text: player.trackTitle || player.identity || "unknown"
            color: theme.bright
            font.pixelSize: 13
            font.bold: true
            font.family: theme.fontFamily
            font.weight: Font.Normal
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: player.trackArtist || ""
            visible: text !== ""
            color: theme.dim
            font.pixelSize: 11
            font.family: theme.fontFamily
            font.weight: Font.Normal
            elide: Text.ElideRight
        }
    }

    Row {
        id: controls
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            text: ""
            visible: player.canGoPrevious
            color: theme.text
            font.pixelSize: 15
            font.family: theme.fontFamily
            font.weight: Font.Normal
            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: player.previous() }
        }
        Text {
            text: player.isPlaying ? "" : ""
            visible: player.canTogglePlaying
            color: theme.purple
            font.pixelSize: 17
            font.family: theme.fontFamily
            font.weight: Font.Normal
            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: player.togglePlaying() }
        }
        Text {
            text: ""
            visible: player.canGoNext
            color: theme.text
            font.pixelSize: 15
            font.family: theme.fontFamily
            font.weight: Font.Normal
            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: player.next() }
        }
    }
}
