import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

PopupWindow {
    id: root
    popoutName: "notes"
    title: "notes"
    popupWidth: 480
    popupHeight: 520

    ListModel { id: model }

    Process {
        id: lister
        command: ["bash", "-c", "cd ~/notes && rg --files -g '*.md' 2>/dev/null | sort"]
        stdout: SplitParser {
            onRead: data => {
                if (data.length === 0) return
                model.append({ key: data, label: data, subtitle: "", icon: "󰎞" })
            }
        }
    }

    onOpenChanged: {
        if (open) {
            model.clear()
            lister.running = true
        }
    }

    ListMenuPopup {
        anchors.fill: parent
        active: root.open
        items: model
        emptyText: "no notes found ✧"
        placeholder: "search notes..."

        onSelected: (item, action) => {
            Quickshell.execDetached([Quickshell.env("HOME") + "/dotfiles/bin/open-note", item.key])
            root.closeRequested()
        }
        onCloseRequested: root.closeRequested()
    }
}
