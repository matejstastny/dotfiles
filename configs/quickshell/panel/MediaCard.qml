import QtQuick
import Quickshell.Services.Mpris
import "../"
import "../common"

Rectangle {
    id: root

    required property MprisPlayer player

    implicitHeight: 74
    radius: Theme.radius
    color: Theme.surface
    border.width: Theme.borderWidth
    border.color: Theme.muted

    MaskedImage {
        id: art

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 10
        width: height
        radius: Theme.radiusSmall
        visible: root.player.trackArtUrl
        source: root.player.trackArtUrl || ""
    }

    Column {
        id: text

        anchors.left: art.visible ? art.right : parent.left
        anchors.leftMargin: art.visible ? 12 : 14
        anchors.right: controls.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

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
            visible: text !== ""
            color: Theme.dim
            font.pixelSize: Theme.sizeLabel
            font.family: Theme.fontSans
            font.weight: Theme.weightBody
            elide: Text.ElideRight
        }
    }

    Row {
        id: controls

        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Text {
            text: String.fromCodePoint(0xf04ae)
            visible: root.player.canGoPrevious
            color: prevArea.containsMouse ? Theme.bright : Theme.text
            font.pixelSize: 15
            font.family: Theme.fontMono

            Behavior on color {
                ColorAnimation {
                    duration: Theme.transitionDuration
                }
            }

            MouseArea {
                id: prevArea
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.player.previous()
            }
        }

        Rectangle {
            width: 30
            height: 30
            radius: width / 2
            visible: root.player.canTogglePlaying
            color: playArea.pressed ? Theme.bright : Theme.purple
            scale: playArea.pressed ? 0.88 : 1

            Text {
                anchors.centerIn: parent
                text: root.player.isPlaying ? String.fromCodePoint(0xf03e4) : String.fromCodePoint(0xf040a)
                color: playArea.pressed ? Theme.base : Theme.bright
                font.pixelSize: 16
                font.family: Theme.fontMono
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Theme.transitionDuration
                    easing.type: Easing.OutCubic
                }
            }

            MouseArea {
                id: playArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.player.togglePlaying()
            }
        }

        Text {
            text: String.fromCodePoint(0xf04ad)
            visible: root.player.canGoNext
            color: nextArea.containsMouse ? Theme.bright : Theme.text
            font.pixelSize: 15
            font.family: Theme.fontMono

            Behavior on color {
                ColorAnimation {
                    duration: Theme.transitionDuration
                }
            }

            MouseArea {
                id: nextArea
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.player.next()
            }
        }
    }

    Row {
        id: modes

        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5
        spacing: 12
        visible: root.player.shuffleSupported || root.player.loopSupported

        Text {
            text: String.fromCodePoint(0xf0496)
            visible: root.player.shuffleSupported
            color: root.player.shuffle ? Theme.purple : (shuffleArea.containsMouse ? Theme.bright : Theme.dim)
            font.pixelSize: 13
            font.family: Theme.fontMono

            Behavior on color { ColorAnimation { duration: Theme.transitionDuration } }

            MouseArea {
                id: shuffleArea
                anchors.fill: parent
                anchors.margins: -5
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.player.shuffle = !root.player.shuffle
            }
        }

        Text {
            text: root.player.loopState === MprisLoopState.Track
                ? String.fromCodePoint(0xf0458)
                : String.fromCodePoint(0xf0456)
            visible: root.player.loopSupported
            color: root.player.loopState !== MprisLoopState.None ? Theme.purple : (loopArea.containsMouse ? Theme.bright : Theme.dim)
            font.pixelSize: 13
            font.family: Theme.fontMono

            Behavior on color { ColorAnimation { duration: Theme.transitionDuration } }

            MouseArea {
                id: loopArea
                anchors.fill: parent
                anchors.margins: -5
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.player.loopState === MprisLoopState.None)
                        root.player.loopState = MprisLoopState.Playlist;
                    else if (root.player.loopState === MprisLoopState.Playlist)
                        root.player.loopState = MprisLoopState.Track;
                    else
                        root.player.loopState = MprisLoopState.None;
                }
            }
        }
    }

}
