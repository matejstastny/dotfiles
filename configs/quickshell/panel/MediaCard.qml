import QtQuick
import Quickshell.Services.Mpris
import "../"
import "../common"

Rectangle {
    id: root

    required property MprisPlayer player

    implicitHeight: 78
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

    Item {
        id: controls

        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: 48
        height: 48
        visible: root.player.canTogglePlaying

        Repeater {
            model: 8

            delegate: Rectangle {
                required property int index
                readonly property real angle: index * 45
                readonly property real radians: angle * Math.PI / 180

                width: 14
                height: 14
                radius: width / 2
                x: controls.width / 2 - width / 2 + Math.cos(radians) * 14
                y: controls.height / 2 - height / 2 + Math.sin(radians) * 14
                color: Theme.purple
            }
        }

        Rectangle {
            id: playButton
            anchors.centerIn: parent
            width: 36
            height: 36
            radius: width / 2
            color: Theme.purple
            scale: playArea.pressed ? 0.88 : (playArea.containsMouse ? 1.06 : 1)

            Canvas {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -2
                anchors.verticalCenterOffset: -1
                width: 22
                height: 22
                visible: !root.player.isPlaying
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.fillStyle = Theme.bright;
                    ctx.beginPath();
                    ctx.moveTo(9.8, 4.7);
                    ctx.bezierCurveTo(8.1, 3.8, 6.5, 4.9, 6.5, 6.9);
                    ctx.lineTo(6.5, 17.1);
                    ctx.bezierCurveTo(6.5, 19.1, 8.2, 20.2, 9.9, 19.2);
                    ctx.lineTo(19.1, 13.8);
                    ctx.bezierCurveTo(20.9, 12.8, 20.9, 11.2, 19.1, 10.2);
                    ctx.lineTo(9.8, 4.7);
                    ctx.fill();
                }
                Component.onCompleted: requestPaint()
            }

            Row {
                anchors.centerIn: parent
                visible: root.player.isPlaying
                spacing: 4

                Repeater {
                    model: 2

                    delegate: Rectangle {
                        required property int index
                        width: 5
                        height: 14
                        radius: width / 2
                        color: Theme.bright
                    }
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Theme.spatialDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.easingSpatial
                }
            }
        }

        MouseArea {
            id: playArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.player.togglePlaying()
        }
    }

}
