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
    readonly property string thumbsScript: homeDir + "/dotfiles/bin/wallpaper-thumbs"
    readonly property string favoriteScript: homeDir + "/dotfiles/bin/wallpaper-favorite"
    readonly property string deleteScript: homeDir + "/dotfiles/bin/wallpaper-delete"

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

    function toggleFavorite(index) {
        const item = wallpaperModel.get(index)
        const next = !item.favorite
        wallpaperModel.setProperty(index, "favorite", next)
        Quickshell.execDetached([root.favoriteScript, item.path, next ? "add" : "remove"])

        const entries = []
        for (let i = 0; i < wallpaperModel.count; i++) entries.push(wallpaperModel.get(i))
        entries.sort((a, b) => {
            if (a.favorite !== b.favorite) return a.favorite ? -1 : 1
            return a.path < b.path ? -1 : (a.path > b.path ? 1 : 0)
        })
        wallpaperModel.clear()
        for (const e of entries) wallpaperModel.append({ path: e.path, thumb: e.thumb, favorite: e.favorite })
    }

    function deleteWallpaper(index) {
        const item = wallpaperModel.get(index)
        Quickshell.execDetached([root.deleteScript, item.path])
        wallpaperModel.remove(index)
        if (grid.currentIndex >= wallpaperModel.count) grid.currentIndex = wallpaperModel.count - 1
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
        command: [root.thumbsScript, root.wallpaperDir]
        stdout: SplitParser {
            onRead: data => {
                if (data.length === 0) return
                const parts = data.split("\t")
                if (parts.length < 3) return
                wallpaperModel.append({ favorite: parts[0] === "1", path: parts[1], thumb: parts[2] })
                if (wallpaperModel.count === 1) grid.currentIndex = 0
            }
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: theme.radius
        color: theme.base
        border.width: theme.borderWidth
        border.color: theme.muted

        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: theme.transitionDuration; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: theme.popDuration; easing.type: Easing.OutBack; easing.overshoot: theme.popOvershoot } }

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
                required property string thumb
                required property bool favorite
                required property int index
                width: grid.cellWidth - 8
                height: grid.cellHeight - 8

                Rectangle {
                    anchors.fill: parent
                    radius: theme.radiusSmall
                    color: theme.surface
                    border.width: theme.borderWidth
                    border.color: theme.muted
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: "file://" + cell.thumb
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        cache: true
                        sourceSize.width: width
                        sourceSize.height: height
                    }
                }

                MouseArea {
                    id: applyArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        grid.currentIndex = index
                        root.applyWallpaper(cell.path)
                    }
                }

                Text {
                    id: favIcon
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 5
                    z: 10
                    text: cell.favorite ? "✦" : "✧"
                    color: cell.favorite ? theme.purple : theme.bright
                    font.pixelSize: 14
                    font.family: theme.fontFamily
                    opacity: cell.favorite || applyArea.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleFavorite(cell.index)
                    }
                }

                Text {
                    id: delIcon
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 5
                    z: 10
                    text: "✕"
                    color: theme.rose
                    font.pixelSize: 12
                    font.family: theme.fontFamily
                    opacity: applyArea.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.deleteWallpaper(cell.index)
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
