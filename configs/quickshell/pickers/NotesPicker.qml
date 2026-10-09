import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../common"

CommandPicker {
    id: root

    popoutName: "notes"
    placeholder: "notes"
    emptyText: "no notes"

    property var notes: []

    // collected whole rather than appended line by line: a SplitParser feeding
    // rows in one at a time made the list visibly build itself on every open
    Process {
        id: lister
        command: ["bash", "-c", "cd ~/notes && rg --files -g '*.md' 2>/dev/null | sort"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    if (line.length === 0)
                        continue;
                    out.push({ key: line, label: line, icon: "󰎞" });
                }
                root.notes = out;
            }
        }
    }

    rows: root.notes

    onOpenChanged: if (root.open)
        lister.running = true

    onSelected: item => {
        Quickshell.execDetached([Quickshell.env("HOME") + "/dotfiles/scripts/open-note.sh", item.key]);
        root.closeRequested();
    }
}
