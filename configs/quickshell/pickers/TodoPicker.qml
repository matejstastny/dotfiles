import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../common"

CommandPicker {
    id: root

    popoutName: "todo"
    mode: "listOrFreeText"
    emptyText: "nothing open"

    property string profile: "personal"
    readonly property string label: root.profile === "stars" ? "stars" : "personal"
    readonly property string file: Quickshell.env("HOME") + "/notes/todo/" + root.profile + ".md"

    // the prompt is the only label this has, so it carries which list you are
    // looking at. there is no title bar to put it in any more
    placeholder: root.label + " todo, or type a new one"

    property var todos: []

    Process {
        id: lister
        command: ["bash", "-c", "mkdir -p ~/notes/todo; " + "[ -f '" + root.file + "' ] || printf '#todo #" + root.profile + "\\n\\n' > '" + root.file + "'; " + "grep '^- \\[ \\]' '" + root.file + "' 2>/dev/null | sed 's/^- \\[ \\] //'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    if (line.length === 0)
                        continue;
                    out.push({ key: line, label: line, icon: "☐" });
                }
                root.todos = out;
            }
        }
    }

    rows: root.todos

    onOpenChanged: if (root.open)
        lister.running = true

    onSelected: item => {
        Quickshell.execDetached([Quickshell.env("HOME") + "/dotfiles/scripts/todo-mark-done.sh", root.file, item.key]);
        root.closeRequested();
    }

    onFreeTextSubmitted: text => {
        if (text.trim().length > 0)
            Quickshell.execDetached([Quickshell.env("HOME") + "/dotfiles/scripts/todo-add.sh", root.file, text]);
        root.closeRequested();
    }
}
