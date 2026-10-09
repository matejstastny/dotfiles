import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../common"

CommandPicker {
    id: root

    popoutName: "code"
    mode: "listOrFreeText"
    placeholder: "project, or paste a path to add"
    emptyText: "no projects"

    readonly property string codeOpenScript: Quickshell.env("HOME") + "/dotfiles/scripts/code-open.sh"
    readonly property string codeForgetScript: Quickshell.env("HOME") + "/dotfiles/scripts/code-forget.sh"

    actions: [
        {
            key: "remove",
            code: Qt.Key_Backspace,
            hint: "alt+backspace  remove"
        },
        {
            key: "devcontainer",
            code: Qt.Key_D,
            hint: "alt+d  devcontainer"
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

    property var projects: []

    Process {
        id: lister
        command: [Quickshell.env("HOME") + "/dotfiles/scripts/code-projects.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0) {
                    root.projects = [];
                    return;
                }
                const out = [];
                for (const e of JSON.parse(text))
                    out.push({
                        key: e.path,
                        label: e.display,
                        icon: e.devcontainer ? "󰡨" : "󰉋"
                    });
                root.projects = out;
            }
        }
    }

    rows: root.projects

    onOpenChanged: if (root.open)
        lister.running = true

    onSelected: (item, action) => {
        if (action === "remove") {
            Quickshell.execDetached([root.codeForgetScript, item.key]);
            lister.running = true;
            return;
        }
        if (action === "devcontainer")
            Quickshell.execDetached([root.codeOpenScript, item.key, "--devcontainer"]);
        else
            Quickshell.execDetached([root.codeOpenScript, item.key]);
        root.closeRequested();
    }

    onFreeTextSubmitted: (text, action) => {
        if (action === "remove")
            return;
        const path = root.resolvePath(text);
        if (path.length === 0)
            return;
        if (action === "devcontainer")
            Quickshell.execDetached([root.codeOpenScript, path, "--devcontainer"]);
        else
            Quickshell.execDetached([root.codeOpenScript, path]);
        root.closeRequested();
    }
}
