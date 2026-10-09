import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../common"

CommandPicker {
    id: root

    popoutName: "keyboard"
    placeholder: "keyboard layout"
    mode: "list"

    // which layout is live is state, not an explanation of the row you happen
    // to be on, so it stays visible on every row
    quietSubtitles: false

    readonly property var layouts: [
        {
            key: "us",
            label: "english",
            code: "us"
        },
        {
            key: "cz",
            label: "czech (qwerty)",
            code: "cz"
        }
    ]

    property string activeKeymap: ""

    rows: {
        const out = [];
        for (let i = 0; i < root.layouts.length; i++) {
            const l = root.layouts[i];
            out.push({
                key: l.key,
                label: l.label,
                subtitle: root.activeKeymap.includes(l.code) ? "active" : l.code,
                icon: "󰌌",
                layoutIndex: i
            });
        }
        return out;
    }

    Process {
        id: activeCheck
        command: ["bash", "-c", "hyprctl devices -j | jq -r '.keyboards[0].active_keymap'"]
        stdout: StdioCollector {
            onStreamFinished: root.activeKeymap = text.trim().toLowerCase()
        }
    }

    onOpenChanged: if (root.open)
        activeCheck.running = true

    onSelected: item => {
        Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", item.layoutIndex.toString()]);
        root.closeRequested();
    }
}
