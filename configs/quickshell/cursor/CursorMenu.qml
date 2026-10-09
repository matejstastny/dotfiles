import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../common"

// was a grid of cramped bordered tiles that never took focus and never set a
// starting index, so the arrow keys did nothing. it is a list now, like every
// other surface here: searchable, keyboard-first, with the preview sitting in
// the same column every other picker puts its mark in
CommandPicker {
    id: root

    popoutName: "cursormenu"
    placeholder: "cursor theme"
    emptyText: "no cursor themes"

    // the previews are pictures, so the mark column has to be wider than a
    // glyph and the rows taller than a line of text
    iconColumnWidth: 44
    rowHeight: 42
    maxRows: 6

    // which theme is live is state, not an explanation of the current row
    quietSubtitles: false

    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string setCursorScript: homeDir + "/dotfiles/scripts/set-cursor.sh"
    readonly property string thumbsScript: homeDir + "/dotfiles/scripts/cursor-thumbs.sh"

    readonly property int minSize: 16
    readonly property int maxSize: 96
    readonly property int sizeStep: 4

    property string currentTheme: ""
    property int currentSize: 24
    property var themes: []

    actions: [
        {
            key: "smaller",
            code: Qt.Key_Minus,
            hint: "alt+− / alt+=  size"
        },
        {
            key: "bigger",
            code: Qt.Key_Equal
        },
        {
            key: "bigger",
            code: Qt.Key_Plus
        }
    ]

    function applyCursor(name: string, size: int): void {
        Quickshell.execDetached([root.setCursorScript, name, String(size)]);
        root.currentTheme = name;
        root.currentSize = size;
        root.closeRequested();
    }

    function nudgeSize(delta: int): void {
        if (root.currentTheme.length === 0)
            return;
        const next = Math.max(root.minSize, Math.min(root.maxSize, root.currentSize + delta));
        if (next === root.currentSize)
            return;
        root.currentSize = next;
        root.commitSize(next);
    }

    function commitSize(size: int): void {
        applyProc.command = [root.setCursorScript, root.currentTheme, String(size)];
        applyProc.running = true;
    }

    Process {
        id: lister
        command: [root.thumbsScript]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    if (line.length === 0)
                        continue;
                    const parts = line.split("\t");
                    if (parts.length < 4)
                        continue;
                    const live = parts[0] === "1";
                    const size = parseInt(parts[3]) || 24;
                    if (live) {
                        root.currentTheme = parts[1];
                        root.currentSize = size;
                    }
                    out.push({
                        key: parts[1],
                        label: parts[1],
                        iconImage: "file://" + parts[2],
                        subtitle: live ? "✦ active" : "",
                        highlighted: live,
                        themeSize: size
                    });
                }
                root.themes = out;
            }
        }
    }

    Process {
        id: applyProc
        // hyprland only repaints the on-screen cursor when a surface requests a
        // differently-*named* shape - applying a new theme/size alone doesn't
        // trigger that. flipping a cursorShape twice (deferred a tick apart so
        // each change is a distinct request, not coalesced) forces two real
        // shape transitions once the new theme/size is actually live
        onExited: nudgeStep1.start()
    }

    property bool nudged: false

    Timer {
        id: nudgeStep1
        interval: 0
        onTriggered: {
            root.nudged = !root.nudged;
            nudgeStep2.start();
        }
    }

    Timer {
        id: nudgeStep2
        interval: 0
        onTriggered: root.nudged = !root.nudged
    }

    rows: root.themes

    onOpenChanged: if (root.open)
        lister.running = true

    onSelected: (item, action) => {
        if (action === "smaller") {
            root.nudgeSize(-root.sizeStep);
            return;
        }
        if (action === "bigger") {
            root.nudgeSize(root.sizeStep);
            return;
        }
        root.applyCursor(item.key, root.currentSize);
    }

    // the size keys still have to land when the filter has left nothing selected
    onFreeTextSubmitted: (text, action) => {
        if (action === "smaller")
            root.nudgeSize(-root.sizeStep);
        else if (action === "bigger")
            root.nudgeSize(root.sizeStep);
    }

    mode: "listOrFreeText"

    body: Component {
        Item {
            id: cursorBody

            implicitWidth: root.surfaceWidth
            implicitHeight: list.implicitHeight + Theme.gapLarge + sizeRow.height

            CommandList {
                id: list

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: implicitHeight

                active: root.open
                rows: root.rows
                actions: root.actions
                mode: root.mode
                placeholder: root.placeholder
                emptyText: root.emptyText
                quietSubtitles: root.quietSubtitles
                rowHeight: root.rowHeight
                maxRows: root.maxRows
                iconColumnWidth: root.iconColumnWidth

                Component.onCompleted: root.view = list
                Component.onDestruction: if (root.view === list)
                    root.view = null

                onSelected: (item, action) => root.selected(item, action)
                onFreeTextSubmitted: (text, action) => root.freeTextSubmitted(text, action)
                onCloseRequested: root.closeRequested()
            }

            // a hairline, not a card edge. the drawer is already one surface
            Rectangle {
                anchors.bottom: sizeRow.top
                anchors.bottomMargin: Theme.gap
                anchors.left: parent.left
                anchors.right: parent.right
                height: Theme.borderWidth
                color: Theme.muted
                opacity: 0.4
            }

            Item {
                id: sizeRow

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Theme.iconLarge

                readonly property real fraction: (root.currentSize - root.minSize) / (root.maxSize - root.minSize)

                Text {
                    id: sizeLabel

                    anchors.left: parent.left
                    anchors.leftMargin: Theme.rowGutter
                    anchors.verticalCenter: parent.verticalCenter
                    text: "size"
                    color: Theme.muted
                    font.pixelSize: Theme.sizeLabel
                    font.family: Theme.fontMono
                }

                Item {
                    id: trackHit

                    anchors.left: sizeLabel.right
                    anchors.leftMargin: Theme.gapLarge
                    anchors.right: valueLabel.left
                    anchors.rightMargin: Theme.gapLarge
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 3
                        radius: height / 2
                        color: Theme.overlay

                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height
                            radius: parent.radius
                            width: Math.max(parent.height, parent.width * Math.max(0, Math.min(1, sizeRow.fraction)))
                            color: Theme.purple

                            Behavior on width {
                                NumberAnimation {
                                    duration: Theme.snapDuration
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.currentTheme.length > 0
                        cursorShape: root.nudged ? Qt.SizeAllCursor : Qt.SizeHorCursor
                        function pick(x) {
                            const t = Math.max(0, Math.min(1, x / trackHit.width));
                            root.currentSize = Math.round(root.minSize + t * (root.maxSize - root.minSize));
                        }
                        onPressed: mouse => pick(mouse.x)
                        onPositionChanged: mouse => {
                            if (pressed)
                                pick(mouse.x);
                        }
                        onReleased: root.commitSize(root.currentSize)
                    }
                }

                Text {
                    id: valueLabel

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    horizontalAlignment: Text.AlignRight
                    text: root.currentSize + "px"
                    color: Theme.bright
                    font.pixelSize: Theme.sizeLabel
                    font.family: Theme.fontMono
                }
            }
        }
    }
}
