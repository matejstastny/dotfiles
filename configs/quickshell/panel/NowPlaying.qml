import QtQuick
import Quickshell.Services.Mpris
import "../"
import "../common"

// cover, title, artist. nothing else - no seek line, no transport, no album,
// no running time. the bar already says what is playing and the media keys
// already control it; this is the picture and the name
Item {
    id: root

    required property MprisPlayer player

    readonly property int artSize: 60

    implicitHeight: root.artSize

    MaskedImage {
        id: art

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: root.artSize
        height: root.artSize
        radius: Theme.radiusSmall
        visible: root.player.trackArtUrl
        source: root.player.trackArtUrl || ""
    }

    // a player with no art still gets a square, so the text column never
    // shifts left and right as tracks change
    Rectangle {
        anchors.fill: art
        visible: !art.visible
        radius: Theme.radiusSmall
        color: Theme.surface
        border.width: Theme.borderWidth
        border.color: Theme.muted

        Text {
            anchors.centerIn: parent
            text: "✦"
            color: Theme.muted
            font.pixelSize: Theme.iconLarge
            font.family: Theme.fontMono
        }
    }

    Column {
        anchors.left: art.right
        anchors.leftMargin: Theme.gapLarge
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            width: parent.width
            text: root.player.trackTitle || root.player.identity || "unknown"
            color: Theme.bright
            font.pixelSize: Theme.sizeBody
            font.family: Theme.fontSans
            font.weight: Theme.weightHeading
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.player.trackArtist || ""
            visible: text.length > 0
            color: Theme.dim
            font.pixelSize: Theme.sizeLabel
            font.family: Theme.fontSans
            elide: Text.ElideRight
        }
    }
}
