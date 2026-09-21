import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../"

Item {
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

    implicitWidth: 1080
    implicitHeight: 230

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

    Item {
        id: card
        anchors.fill: parent

        PathView {
            id: grid
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 16
            clip: true
            property int cardWidth: Math.min(340, Math.max(230, Math.round(height * 1.62)))
            property int cardHeight: Math.round(cardWidth * 9 / 16)
            model: wallpaperModel
            pathItemCount: Math.min(5, Math.max(1, count))
            cacheItemCount: 4
            snapMode: PathView.SnapToItem
            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5
            highlightRangeMode: PathView.StrictlyEnforceRange

            path: Path {
                startY: grid.height / 2

                PathAttribute {
                    name: "z"
                    value: 0
                }
                PathLine {
                    x: grid.width / 2
                    relativeY: 0
                }
                PathAttribute {
                    name: "z"
                    value: 1
                }
                PathLine {
                    x: grid.width
                    relativeY: 0
                }
            }

            focus: root.open
            Keys.onEscapePressed: root.closeRequested()
            Keys.onLeftPressed: grid.decrementCurrentIndex()
            Keys.onRightPressed: grid.incrementCurrentIndex()
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
                width: grid.cardWidth
                height: grid.cardHeight
                scale: PathView.isCurrentItem ? 1 : (PathView.onPath ? 0.78 : 0.5)
                opacity: PathView.onPath ? (PathView.isCurrentItem ? 1 : 0.5) : 0
                z: PathView.isCurrentItem ? 100 : (PathView.z ?? 0)

                Behavior on scale {
                    NumberAnimation {
                        duration: theme.drawerDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: theme.easingDrawer
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: theme.effectsDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: theme.easingEffects
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: theme.radius
                    color: theme.surface
                    border.width: PathView.isCurrentItem ? 2 : theme.borderWidth
                    border.color: PathView.isCurrentItem ? theme.purple : theme.muted
                    clip: true

                    Image {
                        id: thumbnail
                        anchors.fill: parent
                        source: "file://" + cell.thumb
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        cache: true
                        sourceSize.width: width
                        sourceSize.height: height
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: thumbnailMask
                        }
                    }

                    Item {
                        id: thumbnailMask
                        anchors.fill: thumbnail
                        visible: false
                        layer.enabled: true

                        Rectangle {
                            anchors.fill: parent
                            radius: theme.radius - 1
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -5
                    radius: theme.radius + 5
                    color: "transparent"
                    border.width: 1
                    border.color: theme.purple
                    opacity: PathView.isCurrentItem ? 0.45 : 0

                    Behavior on opacity { NumberAnimation { duration: theme.effectsDuration } }
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
