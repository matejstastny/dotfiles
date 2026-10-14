import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../common"

CommandPicker {
    id: root

    popoutName: "diffie"
    mode: "listOrFreeText"
    placeholder: "repository, or paste a path to review"
    emptyText: "no repositories"

    readonly property string diffieOpenScript: Quickshell.env("HOME") + "/dotfiles/scripts/diffie-open.sh"

    actions: [
        {
            key: "remove",
            code: Qt.Key_Backspace,
            hint: "alt+backspace  remove"
        }
    ]

    function resolvePath(p: string): string {
        p = p.trim();
        if (p === "~")
            return Quickshell.env("HOME");
        if (p.startsWith("~/"))
            return Quickshell.env("HOME") + p.slice(1);
        return p;
    }

    property var repositories: []

    Process {
        id: lister
        command: [Quickshell.env("HOME") + "/dotfiles/scripts/code-projects.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0) {
                    root.repositories = [];
                    return;
                }
                const out = [];
                for (const entry of JSON.parse(text))
                    out.push({
                        key: entry.path,
                        label: entry.display,
                        subtitle: "review branch",
                        icon: "󰘦",
                        accent: Theme.rose
                    });
                root.repositories = out;
            }
        }
    }

    rows: root.repositories

    onOpenChanged: if (root.open)
        lister.running = true

    onSelected: (item, action) => {
        if (action === "remove") {
            Quickshell.execDetached([Quickshell.env("HOME") + "/dotfiles/scripts/code-forget.sh", item.key]);
            lister.running = true;
            return;
        }
        Quickshell.execDetached([root.diffieOpenScript, item.key]);
        root.closeRequested();
    }

    onFreeTextSubmitted: (text, action) => {
        if (action === "remove")
            return;
        const path = root.resolvePath(text);
        if (path.length === 0)
            return;
        Quickshell.execDetached([root.diffieOpenScript, path]);
        root.closeRequested();
    }
}
