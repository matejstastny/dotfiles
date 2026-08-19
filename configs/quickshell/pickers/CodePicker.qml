import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

PopupWindow {
    id: root
    popoutName: "code"
    title: "code"
    popupWidth: 520
    popupHeight: 520

    readonly property string codeOpenScript: Quickshell.env("HOME") + "/dotfiles/bin/code-open"
    readonly property string codeForgetScript: Quickshell.env("HOME") + "/dotfiles/bin/code-forget"

    function resolvePath(p) {
        p = p.trim()
        if (p === "~") return Quickshell.env("HOME")
        if (p.startsWith("~/")) return Quickshell.env("HOME") + p.slice(1)
        return p
    }

    ListModel { id: model }

    function reload() {
        model.clear()
        lister.running = true
    }

    Process {
        id: lister
        command: [Quickshell.env("HOME") + "/dotfiles/bin/code-projects"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0) return
                const entries = JSON.parse(text)
                for (const e of entries) {
                    model.append({
                        key: e.path,
                        label: e.display,
                        subtitle: "",
                        icon: e.devcontainer ? "󰡨" : "󰉋"
                    })
                }
            }
        }
    }

    onOpenChanged: {
        if (open) reload()
    }

    ListMenuPopup {
        anchors.fill: parent
        active: root.open
        mode: "listOrFreeText"
        items: model
        emptyText: "no projects found ✧"
        placeholder: "search projects, or paste a path to add..."
        secondaryActionKey: "remove"
        secondaryActionHint: "Alt+Backspace remove"
        tertiaryActionKey: "devcontainer"
        tertiaryActionHint: "Alt+D devcontainer"

        onSelected: (item, action) => {
            if (action === "remove") {
                Quickshell.execDetached([root.codeForgetScript, item.key])
                root.reload()
            } else if (action === "devcontainer") {
                Quickshell.execDetached([root.codeOpenScript, item.key, "--devcontainer"])
                root.closeRequested()
            } else {
                Quickshell.execDetached([root.codeOpenScript, item.key])
                root.closeRequested()
            }
        }
        onFreeTextSubmitted: (text, action) => {
            if (action === "remove") return
            const path = root.resolvePath(text)
            if (path.length === 0) return
            if (action === "devcontainer") {
                Quickshell.execDetached([root.codeOpenScript, path, "--devcontainer"])
            } else {
                Quickshell.execDetached([root.codeOpenScript, path])
            }
            root.closeRequested()
        }
        onCloseRequested: root.closeRequested()
    }
}
