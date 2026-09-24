import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../common"
import "fuzzy.js" as Fuzzy

PopupWindow {
    id: root
    popoutName: "launcher"
    title: ""
    pinTop: true
    // the card re-sizes on nearly every keystroke, so it decelerates flat
    // instead of springing. the pop on open is untouched
    resizeDuration: 0
    resizeEasing: Theme.easingEffects

    readonly property string mruScript: Quickshell.env("HOME") + "/dotfiles/scripts/launcher-touch.sh"
    readonly property string mruFile: Quickshell.env("HOME") + "/.local/share/quickshell-launcher-mru"
    readonly property string editScript: Quickshell.env("HOME") + "/dotfiles/scripts/launcher-edit.sh"

    readonly property int rowHeight: 30
    readonly property int maxRows: 6
    readonly property int queryHeight: 34
    readonly property int shownRows: Math.min(maxRows, filteredRows.length)

    // the card is only ever as tall as it has answers for. no results at all
    // and it collapses to the prompt line
    popupWidth: 460
    popupHeight: 32 + queryHeight + (shownRows > 0 ? 10 + shownRows * rowHeight : 0)

    // the window keeps its full size so a shrinking card animates inside it
    // rather than getting clipped by a surface that already resized
    windowHeight: 32 + queryHeight + 10 + maxRows * rowHeight

    property var mruIds: []
    property var entries: []
    property var filteredRows: []
    property string calcResult: ""
    property bool calcError: false
    property string calcExpression: ""

    readonly property string calcScript: `
import sys, math
expr = sys.argv[1]
ns = {k: getattr(math, k) for k in dir(math) if not k.startswith('_')}
ns['__builtins__'] = {}
try:
    result = eval(expr, ns)
    if isinstance(result, float) and result == int(result) and abs(result) < 1e15:
        print(int(result))
    else:
        print(result)
except Exception:
    print('?')
`

    readonly property var selected: list.currentIndex >= 0 && list.currentIndex < filteredRows.length
        ? filteredRows[list.currentIndex] : null

    function isCalculation(query: string): bool {
        return /^(?:[0-9.(]|(?:sin|cos|tan|sqrt|log|pi|e)\b)/i.test(query)
            && /^[0-9+\-*/%^().,\s_a-z]+$/i.test(query);
    }

    function rebuildEntries() {
        const rows = []
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay) continue
            const kw = e.keywords && e.keywords.length > 0 ? e.keywords.join(" ") : ""
            rows.push({
                label: e.name,
                markup: Fuzzy.escape(e.name),
                subtitle: e.genericName || e.comment || "",
                haystack: (e.genericName || "") + " " + (e.comment || "") + " " + kw,
                key: e.id,
                ref: e
            })
        }
        root.entries = rows
        root.refilter()
    }

    function mruRank(key) {
        const i = root.mruIds.indexOf(key)
        return i === -1 ? Infinity : i
    }

    function refilter() {
        const query = input.text.trim()
        const rows = []

        if (query.length === 0) {
            for (const e of root.entries)
                rows.push(e)
            rows.sort((a, b) => {
                const ar = root.mruRank(a.key)
                const br = root.mruRank(b.key)
                if (ar !== br) return ar - br
                return a.label.localeCompare(b.label)
            })
            for (const e of rows)
                e.markup = Fuzzy.escape(e.label)
        } else {
            const lower = query.toLowerCase()
            for (const e of root.entries) {
                // fuzzy on the name only. a description is long enough that
                // almost any 4 letters appear in it as a subsequence, so
                // everything but the name has to match literally
                const nameHit = Fuzzy.match(e.label, query)

                let best = nameHit ? nameHit.score : -Infinity
                if (e.haystack.toLowerCase().indexOf(lower) !== -1)
                    best = Math.max(best, 20)
                if (e.key.toLowerCase().indexOf(lower) !== -1)
                    best = Math.max(best, 26)
                if (best === -Infinity) continue

                // recently launched apps get a nudge, never enough to outrank
                // a clean name hit over a buried one
                const rank = root.mruRank(e.key)
                if (rank !== Infinity) best += Math.max(0, 30 - rank * 2)

                e.markup = nameHit
                    ? Fuzzy.highlight(e.label, nameHit.positions, Theme.rose)
                    : Fuzzy.escape(e.label)
                e.score = best
                rows.push(e)
            }
            rows.sort((a, b) => b.score - a.score || a.label.localeCompare(b.label))
        }

        if (root.isCalculation(query) && root.calcResult.length > 0 && !root.calcError) {
            rows.unshift({
                type: "calculation",
                label: root.calcResult,
                markup: Fuzzy.escape(root.calcResult),
                subtitle: "copy result",
                key: "calculation"
            });
        }

        root.filteredRows = rows
        list.currentIndex = rows.length > 0 ? 0 : -1
        scrollAnim.stop()
        list.contentY = 0
    }

    // highlightFollowsCurrentItem is off so the marker can glide, which also
    // means the view will not chase the selection on its own
    function ensureVisible() {
        if (list.currentIndex < 0) return
        const top = list.currentIndex * root.rowHeight
        const max = Math.max(0, list.contentHeight - list.height)
        let target = list.contentY
        if (top < target) target = top
        else if (top + root.rowHeight > target + list.height) target = top + root.rowHeight - list.height
        target = Math.max(0, Math.min(max, target))
        if (Math.abs(target - list.contentY) < 0.5) return
        scrollAnim.to = target
        scrollAnim.restart()
    }

    function move(delta) {
        const n = root.filteredRows.length
        if (n === 0) return
        list.currentIndex = (list.currentIndex + delta + n) % n
        root.ensureVisible()
    }

    function launchCurrent() {
        const item = root.selected
        if (!item) return
        if (item.type === "calculation") {
            Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | wl-copy --type text/plain", "_", item.label])
            root.closeRequested()
            return
        }
        root.mruIds = [item.key].concat(root.mruIds.filter(id => id !== item.key))
        Quickshell.execDetached([root.mruScript, item.key])
        item.ref.execute()
        root.closeRequested()
    }

    function editCurrentDesktopFile() {
        const item = root.selected
        if (!item) return
        Quickshell.execDetached([root.editScript, item.key])
        root.closeRequested()
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { root.rebuildEntries() }
    }

    Process {
        id: mruLoader
        command: ["bash", "-c", "cat '" + root.mruFile + "' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.mruIds = text.split("\n").filter(l => l.length > 0)
                root.rebuildEntries()
            }
        }
    }

    Timer {
        id: calcDebounce
        interval: 120
        onTriggered: {
            root.calcExpression = input.text.trim()
            calcProcess.running = true
        }
    }

    Process {
        id: calcProcess
        command: ["python3", "-c", root.calcScript, root.calcExpression]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.calcExpression !== input.text.trim()) {
                    if (root.isCalculation(input.text.trim()))
                        calcDebounce.restart();
                    return;
                }
                const result = text.trim()
                root.calcError = result === "?"
                root.calcResult = root.calcError ? "" : result
                root.refilter()
            }
        }
    }

    Component.onCompleted: mruLoader.running = true

    onOpenChanged: {
        if (open) {
            input.text = ""
            root.calcResult = ""
            root.calcError = false
            refilter()
            input.forceActiveFocus()
        }
    }

    Item {
        id: queryRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.queryHeight

        // the prompt is the only "no results" feedback there is - no error
        // row, the mark just goes cold
        Text {
            id: glyph
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "✦"
            color: root.filteredRows.length > 0 ? Theme.purple : Theme.muted
            font.pixelSize: 14
            font.family: Theme.fontMono
            Behavior on color { ColorAnimation { duration: Theme.snapDuration } }
        }

        TextInput {
            id: input
            anchors.left: glyph.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.bright
            font.pixelSize: 16
            font.family: Theme.fontMono
            selectByMouse: true
            selectionColor: Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.45)
            clip: true

            onTextChanged: {
                const query = text.trim()
                root.calcResult = ""
                root.calcError = false
                root.refilter()
                if (root.isCalculation(query))
                    calcDebounce.restart()
                else
                    calcDebounce.stop()
            }
            onAccepted: root.launchCurrent()

            Keys.onEscapePressed: root.closeRequested()
            Keys.onUpPressed: root.move(-1)
            Keys.onDownPressed: root.move(1)
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Tab) {
                    root.move(1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Backtab) {
                    root.move(-1)
                    event.accepted = true
                } else if ((event.modifiers & Qt.AltModifier) && event.key === Qt.Key_D) {
                    root.editCurrentDesktopFile()
                    event.accepted = true
                }
            }
        }
    }

    ListView {
        id: list
        anchors.top: queryRow.bottom
        anchors.topMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        interactive: false
        model: root.filteredRows
        highlightFollowsCurrentItem: false
        currentIndex: -1

        NumberAnimation {
            id: scrollAnim
            target: list
            property: "contentY"
            duration: Theme.snapDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.easingEffects
        }

        highlight: Item {
            width: list.width
            height: root.rowHeight
            y: list.currentItem ? list.currentItem.y : 0
            opacity: list.currentIndex >= 0 ? 1 : 0

            Behavior on y {
                NumberAnimation { duration: Theme.snapDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easingEffects }
            }
            Behavior on opacity {
                NumberAnimation { duration: Theme.snapDuration }
            }

            // the marker lives in the same left gutter as the prompt mark,
            // so the column reads as one thing down the whole card
            Rectangle {
                x: glyph.width / 2 - 1
                anchors.verticalCenter: parent.verticalCenter
                width: 2
                height: 15
                radius: 1
                color: Theme.purple
            }
        }

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool current: list.currentIndex === index

            width: list.width
            height: root.rowHeight

            Text {
                id: name
                anchors.left: parent.left
                anchors.leftMargin: input.x
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.StyledText
                text: row.modelData.markup
                color: row.modelData.type === "calculation" ? Theme.purple : (row.current ? Theme.bright : Theme.dim)
                font.pixelSize: 13
                font.family: Theme.fontMono
                font.weight: row.modelData.type === "calculation" ? Theme.weightHeading : Theme.weightBody
            }

            // only the row you are on explains itself, the rest stay quiet
            Text {
                anchors.left: name.right
                anchors.leftMargin: 14
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                text: row.modelData.subtitle
                color: Theme.muted
                font.pixelSize: 10
                font.family: Theme.fontMono
                elide: Text.ElideRight
                opacity: row.current ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.snapDuration } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { list.currentIndex = row.index; root.launchCurrent() }
            }
        }
    }
}
