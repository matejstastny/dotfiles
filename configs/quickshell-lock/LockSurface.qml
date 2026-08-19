import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "./common"

Item {
    id: root

    required property var context
    property var screen

    readonly property Theme theme: Theme {}
    readonly property string wallpaperStateFile: Quickshell.env("HOME") + "/.local/state/wallpaper"
    property string wallpaperPath: ""

    opacity: context.unlocking ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: context.unlockFadeDuration; easing.type: Easing.InCubic } }

    QtObject {
        id: clock
        property date now: new Date()
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.now = new Date() }

    focus: true
    Keys.onPressed: event => {
        if (context.unlocking) {
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Backspace) {
            context.currentText = context.currentText.slice(0, -1)
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            context.tryUnlock()
        } else if (event.text.length > 0 && event.text.charCodeAt(0) >= 32) {
            context.currentText += event.text
        }
        event.accepted = true
    }

    FileView {
        id: wallpaperStateFileView
        // blocking: this is a tiny file and we need the path before the
        // Image below can start its (much slower) async load - avoids
        // losing an extra subprocess-spawn's worth of time to a black flash
        path: root.wallpaperStateFile
        blockLoading: true

        Component.onCompleted: {
            const p = text().trim()
            if (p) root.wallpaperPath = p
        }
    }

    Rectangle {
        anchors.fill: parent
        color: theme.base
    }

    Image {
        id: bgImage
        anchors.fill: parent
        source: root.wallpaperPath ? "file://" + root.wallpaperPath : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        visible: false
    }

    MultiEffect {
        id: bgEffect
        anchors.fill: parent
        source: bgImage
        opacity: bgImage.status === Image.Ready ? 1 : 0
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        brightness: -0.25
        saturation: -0.15

        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.55)
    }

    Repeater {
        model: 26
        delegate: Text {
            required property int index
            text: index % 2 === 0 ? "✦" : "✧"
            color: theme.dim
            font.pixelSize: 10 + (index % 3) * 6
            font.family: theme.fontFamily
            x: (index * 137 + 53) % Math.max(root.width, 1)
            y: (index * 251 + 97) % Math.max(root.height, 1)
            opacity: 0.12

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.5; duration: 2200 + (index % 5) * 400; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.1; duration: 2200 + (index % 5) * 400; easing.type: Easing.InOutSine }
            }
        }
    }

    Column {
        id: centerColumn
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -48
        spacing: 10

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.now, "hh:mm")
            color: theme.bright
            font.pixelSize: 52
            font.family: "Playfair Display"
            font.styleName: "Black"
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.now, "dddd, MMMM d")
            color: theme.dim
            font.pixelSize: 12
            font.family: theme.fontFamily
        }

        Item {
            id: inputArea
            anchors.horizontalCenter: parent.horizontalCenter
            width: 200
            height: 30

            transform: Translate { id: shakeTranslate }

            Rectangle {
                anchors.fill: parent
                radius: theme.radiusSmall
                color: theme.overlay
                border.width: root.theme.borderWidth
                border.color: root.context.showFailure ? theme.rose : theme.muted
                Behavior on border.color { ColorAnimation { duration: 150 } }
            }

            Item {
                id: dotsViewport
                anchors.centerIn: parent
                width: 168
                height: 20
                clip: true

                Text {
                    anchors.centerIn: parent
                    visible: root.context.currentText.length === 0
                    text: "✦ password"
                    color: theme.dim
                    font.pixelSize: 11
                    font.italic: true
                    font.family: theme.fontFamily
                }

                ListView {
                    id: charList

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    // once the list is wider than its viewport, shift it left by half the
                    // overflow so the newest (rightmost) char stays fully visible and older
                    // ones scroll off the left edge instead of everything shrinking to fit
                    anchors.horizontalCenterOffset: implicitWidth > dotsViewport.width ? -(implicitWidth - dotsViewport.width) / 2 : 0

                    width: implicitWidth
                    height: implicitHeight
                    implicitWidth: contentWidth
                    implicitHeight: 20

                    orientation: ListView.Horizontal
                    interactive: false
                    spacing: 2

                    Behavior on implicitWidth { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                    model: ScriptModel {
                        values: root.context.currentText.split("")
                    }

                    delegate: Item {
                        id: charDot
                        implicitWidth: 10
                        implicitHeight: charList.implicitHeight

                        ListView.onRemove: SequentialAnimation {
                            PropertyAction { target: charDot; property: "ListView.delayRemove"; value: true }
                            ParallelAnimation {
                                NumberAnimation { target: dotGlyph; property: "opacity"; to: 0; duration: 120 }
                                NumberAnimation { target: dotGlyph; property: "scale"; to: 0.3; duration: 120 }
                            }
                            PropertyAction { target: charDot; property: "ListView.delayRemove"; value: false }
                        }

                        Text {
                            id: dotGlyph
                            anchors.centerIn: parent
                            text: "✦"
                            color: theme.bright
                            font.pixelSize: 20
                            font.family: theme.fontFamily
                            scale: 0
                            opacity: 0

                            SequentialAnimation {
                                running: true
                                ParallelAnimation {
                                    NumberAnimation { target: dotGlyph; property: "scale"; from: 0; to: 1.3; duration: 160; easing.type: Easing.OutBack; easing.overshoot: 3 }
                                    NumberAnimation { target: dotGlyph; property: "opacity"; from: 0; to: 1; duration: 110 }
                                }
                                PauseAnimation { duration: 140 }
                                ParallelAnimation {
                                    NumberAnimation { target: dotGlyph; property: "scale"; to: 0.75; duration: 160; easing.type: Easing.OutCubic }
                                    PropertyAction { target: dotGlyph; property: "text"; value: "●" }
                                }
                            }
                        }
                    }
                }
            }

            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: shakeTranslate; property: "x"; to: -10; duration: 55 }
                NumberAnimation { target: shakeTranslate; property: "x"; to: 10; duration: 55 }
                NumberAnimation { target: shakeTranslate; property: "x"; to: -6; duration: 55 }
                NumberAnimation { target: shakeTranslate; property: "x"; to: 6; duration: 55 }
                NumberAnimation { target: shakeTranslate; property: "x"; to: 0; duration: 55 }
            }
            Connections {
                target: root.context
                function onShowFailureChanged() {
                    if (root.context.showFailure) shakeAnim.start()
                }
            }
        }

    }

    Text {
        anchors.top: centerColumn.bottom
        anchors.topMargin: 10
        anchors.horizontalCenter: centerColumn.horizontalCenter
        text: root.context.unlockInProgress ? "unlocking..." : (root.context.showFailure ? "wrong password ✧" : "")
        color: root.context.showFailure ? theme.rose : theme.dim
        font.pixelSize: 10
        font.family: theme.fontFamily
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        spacing: 8

        Avatar {
            id: avatar
            anchors.horizontalCenter: parent.horizontalCenter
            size: 44
            source: "file://" + Quickshell.env("HOME") + "/pictures/pfp.JPEG"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: avatarBounce.start()
            }

            SequentialAnimation {
                id: avatarBounce
                NumberAnimation { target: avatar; property: "rotation"; to: -14; duration: 80; easing.type: Easing.OutQuad }
                NumberAnimation { target: avatar; property: "rotation"; to: 14; duration: 140; easing.type: Easing.InOutQuad }
                NumberAnimation { target: avatar; property: "rotation"; to: 0; duration: 120; easing.type: Easing.OutBack }
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 1

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    const h = new Date().getHours()
                    const greeting = h < 5 ? "still up" : h < 12 ? "good morning" : h < 18 ? "good afternoon" : h < 23 ? "good evening" : "good night"
                    return greeting + " ✦"
                }
                color: theme.purple
                font.pixelSize: 12
                font.bold: true
                font.family: theme.fontFamily
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Quickshell.env("USER")
                color: theme.dim
                font.pixelSize: 10
                font.family: theme.fontFamily
            }
        }
    }
}
