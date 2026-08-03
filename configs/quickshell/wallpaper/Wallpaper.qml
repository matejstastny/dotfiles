import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../"

PanelWindow {
    id: root

    property bool open: false
    signal closeRequested()

    readonly property Theme theme: Theme {}
    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string wallpaperDir: homeDir + "/wallpapers"
    readonly property string setWallpaperScript: homeDir + "/dotfiles/bin/set-wallpaper"

    visible: open
    color: "transparent"
    implicitWidth: 640
    implicitHeight: 460
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:wallpaper"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    focusable: false

    HyprlandFocusGrab {
        active: root.open
        windows: [QsWindow.window]
        onCleared: root.closeRequested()
    }

    function applyWallpaper(path) {
        Quickshell.execDetached([root.setWallpaperScript, path])
        root.closeRequested()
    }

    onOpenChanged: {
        if (open) {
            wallpaperModel.clear()
            lister.running = true
            PopoutState.current = "wallpaper"
        } else if (PopoutState.current === "wallpaper") {
            PopoutState.current = ""
        }
    }
    Connections {
        target: PopoutState
        function onCurrentChanged() {
            if (PopoutState.current !== "wallpaper" && root.open) root.closeRequested()
        }
    }

    ListModel { id: wallpaperModel }

    Process {
        id: lister
        command: ["bash", "-c",
            "find -L '" + root.wallpaperDir + "' -maxdepth 1 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \\) | sort"]
        stdout: SplitParser {
            onRead: data => {
                if (data.length === 0) return
                wallpaperModel.append({ path: data })
                if (wallpaperModel.count === 1) grid.currentIndex = 0
            }
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: theme.radius
        color: theme.base
        border.width: 1
        border.color: theme.muted

        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        Item {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            height: titleText.implicitHeight

            Text {
                id: titleText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "✦ wallpaper"
                color: theme.purple
                font.pixelSize: 15
                font.bold: true
                font.family: theme.fontFamily
                font.weight: Font.Normal
            }
        }

        GridView {
            id: grid
            anchors.top: header.bottom
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 16
            clip: true
            cellWidth: 152
            cellHeight: 96
            model: wallpaperModel
            boundsBehavior: Flickable.StopAtBounds

            focus: root.open
            keyNavigationEnabled: true
            highlightFollowsCurrentItem: true
            highlightMoveDuration: 100
            highlight: Rectangle {
                width: grid.cellWidth - 8
                height: grid.cellHeight - 8
                radius: theme.radiusSmall
                color: "transparent"
                border.width: 2
                border.color: theme.purple
                z: 10
            }
            Keys.onEscapePressed: root.closeRequested()
            function confirmCurrent() {
                if (grid.currentIndex >= 0) root.applyWallpaper(wallpaperModel.get(grid.currentIndex).path)
            }
            Keys.onReturnPressed: confirmCurrent()
            Keys.onEnterPressed: confirmCurrent()

            delegate: Item {
                id: cell
                required property string path
                required property int index
                width: grid.cellWidth - 8
                height: grid.cellHeight - 8

                Rectangle {
                    anchors.fill: parent
                    radius: theme.radiusSmall
                    color: theme.surface
                    border.width: 1
                    border.color: theme.muted
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: "file://" + cell.path
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        cache: true
                        sourceSize.width: width
                        sourceSize.height: height
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        grid.currentIndex = index
                        root.applyWallpaper(cell.path)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: wallpaperModel.count === 0
                text: "no wallpapers found ✧"
                color: theme.dim
                font.pixelSize: 12
                font.family: theme.fontFamily
                font.weight: Font.Normal
            }
        }
    }
}
