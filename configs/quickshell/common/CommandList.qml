import QtQuick
import "../"
import "fuzzy.js" as Fuzzy

// prompt plus filtered list, and the only one of either in the shell. it sizes
// itself to the answers it has, so the command drawer around it collapses to a
// single prompt line when there is nothing to show
Item {
    id: root

    // plain objects. the keys read here are label, subtitle, icon, keywords and
    // key - anything else rides along untouched and comes back on `selected`
    property var rows: []

    // rows pinned above the filtered set and never filtered out, which is how
    // the launcher's calculator result gets to the top
    property var pinned: []

    property string mode: "list" // "list" | "freeText" | "listOrFreeText"
    property string placeholder: "search..."
    property string emptyText: "nothing here"
    property bool quietSubtitles: true
    property Component rowDelegate: null
    property int rowHeight: Theme.rowHeight
    property int maxRows: Theme.commandMaxRows
    property bool active: false

    // optional per-row score adjustment, function(row) -> number. the launcher
    // uses it for its most-recently-used nudge. with an empty query it orders
    // the list instead, highest first
    property var boost: null

    // { key, hint, mod, code } each. the hint line under the prompt is built
    // from whichever of these carry one
    property var actions: []

    // a wifi password goes through the same prompt as everything else, it just
    // stops echoing. there is no second kind of text field in the shell
    property bool password: false

    // takes the hint line's place when something went wrong, in rose. the only
    // error channel any of these surfaces has
    property string notice: ""

    // a typed string rather than an alias to input.text: an alias reads as
    // undefined while the component is still coming up, and every caller then
    // has to guard a .trim() against it
    readonly property string query: input.text
    readonly property int queryHeight: 34

    signal selected(var item, string action)
    signal freeTextSubmitted(string text, string action)
    signal closeRequested()

    // { item, markup } pairs. the wrapper exists because a row may be a service
    // object with no room to hang a highlighted copy of its own label on
    property var filtered: []

    // what the list was last filtered against. a refilter that is not the
    // result of you typing keeps you where you were: wifi re-reads its networks
    // every five seconds and bluetooth every two, and resetting to the top row
    // each time would walk the selection out from under you mid-arrow
    property string lastQuery: ""

    readonly property int shownRows: Math.min(root.maxRows, root.filtered.length)
    readonly property bool listVisible: root.mode !== "freeText"
    // a picker whose marks are pictures rather than glyphs needs a wider column.
    // 0 means work it out from the rows
    property int iconColumnWidth: 0

    readonly property int iconColumn: {
        if (!root.listVisible)
            return 0;
        const entries = root.filtered ?? [];
        for (let i = 0; i < entries.length; i++) {
            const item = entries[i].item;
            const marked = (item.icon && String(item.icon).length > 0) || (item.iconImage && String(item.iconImage).length > 0) || (item.swatch !== undefined && item.swatch !== null);
            if (marked)
                return root.iconColumnWidth > 0 ? root.iconColumnWidth : Theme.iconSmall + 8;
        }
        return 0;
    }

    readonly property var current: list.currentIndex >= 0 && list.currentIndex < root.filtered.length ? root.filtered[list.currentIndex].item : null

    readonly property string hintLine: {
        const hints = [];
        const defined = root.actions ?? [];
        for (let i = 0; i < defined.length; i++)
            if (defined[i].hint && defined[i].hint.length > 0)
                hints.push(defined[i].hint);
        return hints.join("   ·   ");
    }

    readonly property int headHeight: root.queryHeight + (hintText.visible ? Theme.gapSmall + hintText.implicitHeight : 0)

    implicitHeight: root.headHeight + (root.listVisible && root.shownRows > 0 ? Theme.gap + root.shownRows * root.rowHeight : 0)

    function refilter(): void {
        const query = input.text.trim();
        const out = [];

        const pins = root.pinned ?? [];
        for (let i = 0; i < pins.length; i++) {
            const row = pins[i];
            out.push({
                item: row,
                markup: Fuzzy.escape(String(row.label ?? "")),
                pinned: true
            });
        }

        const source = root.rows ?? [];

        if (query.length === 0) {
            const plain = [];
            for (let i = 0; i < source.length; i++) {
                const row = source[i];
                plain.push({
                    item: row,
                    markup: Fuzzy.escape(String(row.label ?? "")),
                    score: root.boost ? root.boost(row) : 0
                });
            }
            if (root.boost)
                plain.sort((a, b) => b.score - a.score || String(a.item.label ?? "").localeCompare(String(b.item.label ?? "")));
            for (const entry of plain)
                out.push(entry);
        } else {
            const lower = query.toLowerCase();
            const hits = [];
            for (let i = 0; i < source.length; i++) {
                const row = source[i];
                const label = String(row.label ?? "");

                // fuzzy on the label only. a subtitle or a keyword blob is long
                // enough that almost any four letters appear in it as a
                // subsequence, so everything but the label has to match literally
                const nameHit = Fuzzy.match(label, query);
                let best = nameHit ? nameHit.score : -Infinity;

                const haystack = (String(row.subtitle ?? "") + " " + String(row.keywords ?? "")).toLowerCase();
                if (haystack.length > 1 && haystack.indexOf(lower) !== -1)
                    best = Math.max(best, 20);
                const key = String(row.key ?? "").toLowerCase();
                if (key.length > 0 && key.indexOf(lower) !== -1)
                    best = Math.max(best, 26);
                if (best === -Infinity)
                    continue;

                if (root.boost)
                    best += root.boost(row);

                hits.push({
                    item: row,
                    markup: nameHit ? Fuzzy.highlight(label, nameHit.positions, Theme.rose) : Fuzzy.escape(label),
                    score: best
                });
            }
            hits.sort((a, b) => b.score - a.score || String(a.item.label ?? "").localeCompare(String(b.item.label ?? "")));
            for (const entry of hits)
                out.push(entry);
        }

        const query_changed = query !== root.lastQuery;
        const previous = root.current;
        root.lastQuery = query;
        root.filtered = out;

        if (!query_changed && previous) {
            let restored = -1;
            for (let i = 0; i < out.length; i++) {
                if (out[i].item === previous || (previous.key !== undefined && out[i].item.key === previous.key)) {
                    restored = i;
                    break;
                }
            }
            if (restored >= 0) {
                list.currentIndex = restored;
                return;
            }
        }

        list.currentIndex = out.length > 0 ? 0 : -1;
        scrollAnim.stop();
        list.contentY = 0;
    }

    // highlightFollowsCurrentItem is off so the marker can glide, which also
    // means the view will not chase the selection on its own
    function ensureVisible(): void {
        if (list.currentIndex < 0)
            return;
        const top = list.currentIndex * root.rowHeight;
        const max = Math.max(0, list.contentHeight - list.height);
        let target = list.contentY;
        if (top < target)
            target = top;
        else if (top + root.rowHeight > target + list.height)
            target = top + root.rowHeight - list.height;
        target = Math.max(0, Math.min(max, target));
        if (Math.abs(target - list.contentY) < 0.5)
            return;
        scrollAnim.to = target;
        scrollAnim.restart();
    }

    function move(delta: int): void {
        const n = root.filtered.length;
        if (n === 0)
            return;
        list.currentIndex = (list.currentIndex + delta + n) % n;
        root.ensureVisible();
    }

    function moveTo(index: int): void {
        const n = root.filtered.length;
        if (n === 0)
            return;
        list.currentIndex = Math.max(0, Math.min(n - 1, index));
        root.ensureVisible();
    }

    function activate(action: string): void {
        action = action || "default";
        if (root.mode !== "freeText" && list.currentIndex >= 0 && list.currentIndex < root.filtered.length)
            root.selected(root.filtered[list.currentIndex].item, action);
        else if (root.mode !== "list")
            root.freeTextSubmitted(input.text, action);
    }

    function focusInput(): void {
        input.forceActiveFocus();
    }

    function reset(): void {
        input.text = "";
        root.lastQuery = "\u0000";
        root.refilter();
        input.forceActiveFocus();
    }

    onRowsChanged: root.refilter()
    onPinnedChanged: root.refilter()
    onActiveChanged: if (root.active)
        root.reset()
    Component.onCompleted: root.refilter()

    Item {
        id: queryRow

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.queryHeight

        // the prompt is the only "no results" feedback there is - no error row,
        // the mark just goes cold
        Text {
            id: glyph

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.rowGutter
            text: "✦"
            color: !root.listVisible || root.filtered.length > 0 ? Theme.purple : Theme.muted
            font.pixelSize: Theme.iconSmall
            font.family: Theme.fontMono

            Behavior on color {
                ColorAnimation {
                    duration: Theme.snapDuration
                }
            }
        }

        Text {
            visible: input.text.length === 0
            anchors.left: parent.left
            anchors.leftMargin: Theme.rowGutter
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.placeholder
            color: Theme.muted
            font.pixelSize: Theme.sizeInput
            font.family: Theme.fontMono
            elide: Text.ElideRight
        }

        TextInput {
            id: input

            anchors.left: parent.left
            anchors.leftMargin: Theme.rowGutter
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.bright
            font.pixelSize: Theme.sizeInput
            font.family: Theme.fontMono
            selectByMouse: true
            selectionColor: Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.45)
            echoMode: root.password ? TextInput.Password : TextInput.Normal
            clip: true

            onTextChanged: root.refilter()
            onAccepted: root.activate("default")

            Keys.onEscapePressed: root.closeRequested()
            Keys.onUpPressed: root.move(-1)
            Keys.onDownPressed: root.move(1)
            Keys.onPressed: event => {
                // a keyboard-only shell should not make you hold down an arrow
                // to cross two hundred emoji
                if (event.key === Qt.Key_Tab) {
                    root.move(1);
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_Backtab) {
                    root.move(-1);
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_PageDown) {
                    root.move(root.maxRows);
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_PageUp) {
                    root.move(-root.maxRows);
                    event.accepted = true;
                    return;
                }
                if (event.modifiers & Qt.ControlModifier) {
                    if (event.key === Qt.Key_N) {
                        root.move(1);
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_P) {
                        root.move(-1);
                        event.accepted = true;
                        return;
                    }
                    // plain home/end still belong to the text cursor
                    if (event.key === Qt.Key_Home) {
                        root.moveTo(0);
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_End) {
                        root.moveTo(root.filtered.length - 1);
                        event.accepted = true;
                        return;
                    }
                }
                const defined = root.actions ?? [];
                for (let i = 0; i < defined.length; i++) {
                    const action = defined[i];
                    if (event.key !== action.code)
                        continue;
                    const mod = action.mod ?? Qt.AltModifier;
                    if ((event.modifiers & mod) !== mod)
                        continue;
                    root.activate(action.key);
                    event.accepted = true;
                    return;
                }
            }
        }
    }

    Text {
        id: hintText

        visible: root.notice.length > 0 || root.hintLine.length > 0
        anchors.top: queryRow.bottom
        anchors.topMargin: Theme.gapSmall
        anchors.left: parent.left
        anchors.leftMargin: Theme.rowGutter
        anchors.right: parent.right
        text: root.notice.length > 0 ? root.notice : root.hintLine
        color: root.notice.length > 0 ? Theme.rose : Theme.muted
        font.pixelSize: Theme.sizeMicro
        font.family: Theme.fontMono
        elide: Text.ElideRight

        Behavior on color {
            ColorAnimation {
                duration: Theme.snapDuration
            }
        }
    }

    ListView {
        id: list

        visible: root.listVisible
        anchors.top: hintText.visible ? hintText.bottom : queryRow.bottom
        anchors.topMargin: Theme.gap
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        interactive: false
        model: root.filtered
        highlightFollowsCurrentItem: false
        currentIndex: -1
        boundsBehavior: Flickable.StopAtBounds

        NumberAnimation {
            id: scrollAnim

            target: list
            property: "contentY"
            duration: Theme.snapDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.easingEffects
        }

        // the marker lives in the same gutter as the prompt mark, so the column
        // reads as one thing down the whole card
        highlight: Item {
            width: list.width
            height: root.rowHeight
            y: list.currentItem ? list.currentItem.y : 0
            opacity: list.currentIndex >= 0 ? 1 : 0

            Behavior on y {
                NumberAnimation {
                    duration: Theme.snapDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.easingEffects
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.snapDuration
                }
            }

            Rectangle {
                x: Math.round(Theme.rowGutter / 2) - Math.round(Theme.markerWidth / 2) - 3
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.markerWidth
                height: Theme.markerHeight
                radius: Theme.markerWidth / 2
                color: Theme.purple
            }
        }

        delegate: root.rowDelegate ? root.rowDelegate : defaultRow
    }

    Text {
        anchors.centerIn: list
        visible: root.listVisible && root.filtered.length === 0
        text: root.emptyText
        color: Theme.muted
        font.pixelSize: Theme.sizeBody
        font.family: Theme.fontMono
    }

    Component {
        id: defaultRow

        CommandRow {
            id: row

            required property var modelData
            required property int index

            width: ListView.view ? ListView.view.width : 200
            height: root.rowHeight

            current: ListView.isCurrentItem
            icon: row.modelData.item.icon ?? ""
            iconImage: row.modelData.item.iconImage ?? ""
            swatch: row.modelData.item.swatch ?? "transparent"
            label: row.modelData.markup
            subtitle: row.modelData.item.subtitle ?? ""
            quietSubtitle: root.quietSubtitles
            iconColumn: root.iconColumn

            // a row may ask for its own accent and weight - an image in the
            // clipboard, a calculator result - without needing a delegate of
            // its own just to say so
            accent: row.modelData.item.accent ?? Theme.purple
            highlighted: row.modelData.pinned === true || row.modelData.item.highlighted === true
            strong: row.modelData.item.strong === true

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    list.currentIndex = row.index;
                    root.activate("default");
                }
            }
        }
    }
}
