import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

PopupWindow {
    id: root
    popoutName: "cursormenu"
    title: "cursor"
    popupWidth: 520
    popupHeight: 430

    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string setCursorScript: homeDir + "/dotfiles/bin/set-cursor"
    readonly property string thumbsScript: homeDir + "/dotfiles/bin/cursor-thumbs"

    property string currentTheme: ""
    property int currentSize: 24

    function applyCursor(name, size) {
        Quickshell.execDetached([root.setCursorScript, name, String(size)])
        root.currentTheme = name
        root.currentSize = size
        cursorModel.setCurrent(name)
        root.closeRequested()
    }

    onOpenChanged: {
        if (open) {
            cursorModel.clear()
            lister.running = true
        }
    }

    ListModel {
        id: cursorModel
        function setCurrent(name) {
            for (let i = 0; i < count; i++) setProperty(i, "current", get(i).name === name)
        }
        function setSize(name, size) {
            for (let i = 0; i < count; i++) if (get(i).name === name) setProperty(i, "size", size)
        }
    }

    Process {
        id: lister
        command: [root.thumbsScript]
        stdout: SplitParser {
            onRead: data => {
                if (data.length === 0) return
                const parts = data.split("\t")
                if (parts.length < 4) return
                const size = parseInt(parts[3]) || 24
                cursorModel.append({ current: parts[0] === "1", name: parts[1], thumb: parts[2], size: size })
                if (cursorModel.count === 1) grid.currentIndex = 0
                if (parts[0] === "1") {
                    root.currentTheme = parts[1]
                    root.currentSize = size
                }
            }
        }
    }

    GridView {
        id: grid
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: sizeRow.top
        anchors.bottomMargin: 10
        clip: true
        cellWidth: 122
        cellHeight: 108
        model: cursorModel
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
            if (grid.currentIndex >= 0) {
                const item = cursorModel.get(grid.currentIndex)
                root.applyCursor(item.name, item.size)
            }
        }
        Keys.onReturnPressed: confirmCurrent()
        Keys.onEnterPressed: confirmCurrent()

        delegate: Item {
            id: cell
            required property string name
            required property string thumb
            required property bool current
            required property int size
            required property int index
            width: grid.cellWidth - 8
            height: grid.cellHeight - 8

            Rectangle {
                anchors.fill: parent
                radius: theme.radiusSmall
                color: theme.surface
                border.width: theme.borderWidth
                border.color: cell.current ? theme.purple : theme.muted
                clip: true

                Image {
                    id: preview
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 48
                    height: 48
                    source: "file://" + cell.thumb
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    cache: true
                    sourceSize.width: width
                    sourceSize.height: height
                }

                Text {
                    anchors.top: preview.bottom
                    anchors.topMargin: 6
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 4
                    horizontalAlignment: Text.AlignHCenter
                    text: cell.name
                    color: cell.current ? theme.purple : theme.bright
                    font.pixelSize: 9
                    font.family: theme.fontFamily
                    font.weight: Font.Normal
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Text {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 5
                    z: 10
                    text: "✦"
                    color: theme.purple
                    font.pixelSize: 12
                    font.family: theme.fontFamily
                    visible: cell.current
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    grid.currentIndex = index
                    root.applyCursor(cell.name, cell.size)
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: cursorModel.count === 0
            text: "no cursor themes found ✧"
            color: theme.dim
            font.pixelSize: 12
            font.family: theme.fontFamily
            font.weight: Font.Normal
        }
    }

    Item {
        id: sizeRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 20

        readonly property int minSize: 16
        readonly property int maxSize: 96
        readonly property real fraction: (root.currentSize - minSize) / (maxSize - minSize)

        function valueForX(x, w) {
            const t = Math.max(0, Math.min(1, x / w))
            return Math.round(minSize + t * (maxSize - minSize))
        }

        function previewSize(size) {
            root.currentSize = size
        }

        function commitSize(size) {
            applyProc.command = [root.setCursorScript, root.currentTheme, String(size)]
            applyProc.running = true
            cursorModel.setSize(root.currentTheme, size)
        }

        Process {
            id: applyProc
            // hyprland only repaints the on-screen cursor when a surface requests a
            // differently-*named* shape - applying a new theme/size alone doesn't
            // trigger that. flipping trackHit's cursorShape twice (deferred a tick
            // apart so each change is a distinct request, not coalesced) forces two
            // real shape transitions once the new theme/size is actually live.
            onExited: nudgeStep1.start()
        }
        Timer {
            id: nudgeStep1
            interval: 0
            onTriggered: {
                trackHit.nudged = !trackHit.nudged
                nudgeStep2.start()
            }
        }
        Timer {
            id: nudgeStep2
            interval: 0
            onTriggered: trackHit.nudged = !trackHit.nudged
        }

        Text {
            id: sizeLabel
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "size"
            color: theme.dim
            font.pixelSize: 11
            font.family: theme.fontFamily
            font.weight: Font.Normal
        }

        Item {
            id: trackHit
            anchors.left: sizeLabel.right
            anchors.leftMargin: 10
            anchors.right: valueLabel.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height

            property bool nudged: false

            Rectangle {
                id: track
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 6
                radius: 3
                color: theme.overlay

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    radius: parent.radius
                    width: Math.max(radius * 2, parent.width * Math.max(0, Math.min(1, sizeRow.fraction)))
                    color: theme.purple
                    Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.currentTheme.length > 0
                cursorShape: trackHit.nudged ? Qt.SizeAllCursor : Qt.SizeHorCursor
                onPressed: mouse => sizeRow.previewSize(sizeRow.valueForX(mouse.x, trackHit.width))
                onPositionChanged: mouse => {
                    if (pressed) sizeRow.previewSize(sizeRow.valueForX(mouse.x, trackHit.width))
                }
                onReleased: sizeRow.commitSize(root.currentSize)
            }
        }

        Text {
            id: valueLabel
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            horizontalAlignment: Text.AlignRight
            text: root.currentSize + "px"
            color: theme.bright
            font.pixelSize: 11
            font.family: theme.fontFamily
            font.weight: Font.Normal
        }
    }
}
