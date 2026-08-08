import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

PopupWindow {
    id: root
    popoutName: "code"
    title: "code"
    implicitWidth: 520
    implicitHeight: 520

    readonly property string codeOpenScript: Quickshell.env("HOME") + "/dotfiles/bin/code-open"
    readonly property string codeForgetScript: Quickshell.env("HOME") + "/dotfiles/bin/code-forget"

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
        items: model
        emptyText: "no projects found ✧"
        placeholder: "search projects..."
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
        onCloseRequested: root.closeRequested()
    }
}
