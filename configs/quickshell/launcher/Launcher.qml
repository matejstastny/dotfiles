import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../common"

CommandPicker {
    id: root

    popoutName: "launcher"
    placeholder: "run, or do sums"
    emptyText: "nothing matches"

    rows: root.entries
    pinned: root.calcRows
    boost: root.mruBoost

    // no hint: this is the surface that opens most, and a permanent line
    // explaining alt+d is exactly the kind of chrome the launcher does without
    actions: [
        {
            key: "edit",
            code: Qt.Key_D
        }
    ]

    readonly property string mruScript: Quickshell.env("HOME") + "/dotfiles/scripts/launcher-touch.sh"
    readonly property string mruFile: Quickshell.env("HOME") + "/.local/share/quickshell-launcher-mru"
    readonly property string editScript: Quickshell.env("HOME") + "/dotfiles/scripts/launcher-edit.sh"

    property var mruIds: []
    property var entries: []
    property string calcExpression: ""

    // set only when python actually came back with a number, and cleared the
    // moment the query stops looking like arithmetic. a binding that rebuilt
    // this array on every keystroke would re-run the filter twice per letter,
    // since handing CommandList a fresh (even empty) array counts as a change
    property var calcRows: []

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

    function isCalculation(query: string): bool {
        return /^(?:[0-9.(]|(?:sin|cos|tan|sqrt|log|pi|e)\b)/i.test(query) && /^[0-9+\-*/%^().,\s_a-z]+$/i.test(query);
    }

    function rebuildEntries(): void {
        const rows = [];
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay)
                continue;
            const kw = e.keywords && e.keywords.length > 0 ? e.keywords.join(" ") : "";
            rows.push({
                label: e.name,
                subtitle: e.genericName || e.comment || "",
                keywords: (e.genericName || "") + " " + (e.comment || "") + " " + kw,
                key: e.id,
                ref: e
            });
        }
        root.entries = rows;
    }

    function mruRank(key): int {
        const i = root.mruIds.indexOf(key);
        return i === -1 ? Infinity : i;
    }

    // recently launched apps get a nudge, never enough to outrank a clean name
    // hit over a buried one. with no query at all it is the whole ordering
    function mruBoost(row): real {
        const rank = root.mruRank(row.key);
        if (rank === Infinity)
            return 0;
        return Math.max(0, 30 - rank * 2);
    }

    function clearCalc(): void {
        if (root.calcRows.length > 0)
            root.calcRows = [];
    }

    function launch(item: var): void {
        if (item.type === "calculation") {
            Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | wl-copy --type text/plain", "_", item.label]);
            root.closeRequested();
            return;
        }
        root.mruIds = [item.key].concat(root.mruIds.filter(id => id !== item.key));
        Quickshell.execDetached([root.mruScript, item.key]);
        item.ref.execute();
        root.closeRequested();
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.rebuildEntries();
        }
    }

    Process {
        id: mruLoader
        command: ["bash", "-c", "cat '" + root.mruFile + "' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.mruIds = text.split("\n").filter(l => l.length > 0);
                root.rebuildEntries();
            }
        }
    }

    Timer {
        id: calcDebounce
        interval: 120
        onTriggered: {
            root.calcExpression = root.query.trim();
            calcProcess.running = true;
        }
    }

    Process {
        id: calcProcess
        command: ["python3", "-c", root.calcScript, root.calcExpression]
        stdout: StdioCollector {
            onStreamFinished: {
                const query = root.query.trim();
                if (root.calcExpression !== query) {
                    if (root.isCalculation(query))
                        calcDebounce.restart();
                    return;
                }
                const result = text.trim();
                if (result === "?" || result.length === 0) {
                    root.clearCalc();
                    return;
                }
                root.calcRows = [
                    {
                        type: "calculation",
                        label: result,
                        subtitle: "copy result",
                        key: "calculation"
                    }
                ];
            }
        }
    }

    Component.onCompleted: mruLoader.running = true

    onOpenChanged: if (root.open)
        root.clearCalc()

    onQueryChanged: {
        if (root.isCalculation(root.query.trim())) {
            calcDebounce.restart();
        } else {
            calcDebounce.stop();
            root.clearCalc();
        }
    }

    onSelected: (item, action) => {
        if (action === "edit") {
            if (item.type !== "calculation")
                Quickshell.execDetached([root.editScript, item.key]);
            root.closeRequested();
            return;
        }
        root.launch(item);
    }
}
