import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../common"

CommandPicker {
    id: root

    popoutName: "emoji"
    placeholder: "emoji"
    emptyText: "no emoji"

    readonly property string dataFile: Quickshell.env("HOME") + "/dotfiles/configs/quickshell/pickers/data/emoji.json"

    // built once and kept. there are about eighteen hundred of these, and the
    // old version appended them to a ListModel one at a time on every open,
    // which was a visible hitch - a plain array costs one assignment
    property var emoji: []

    Process {
        id: lister
        command: ["cat", root.dataFile]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0)
                    return;
                const out = [];
                for (const e of JSON.parse(text))
                    out.push({
                        key: e.emoji,
                        label: e.name,
                        subtitle: e.keywords.split(", ").slice(0, 3).join(", "),
                        keywords: e.keywords,
                        icon: e.emoji
                    });
                root.emoji = out;
            }
        }
    }

    rows: root.emoji

    onOpenChanged: if (root.open && root.emoji.length === 0)
        lister.running = true

    onSelected: item => {
        Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | wl-copy", "_", item.key]);
        root.closeRequested();
    }
}
