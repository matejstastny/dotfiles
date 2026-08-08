import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

PopupWindow {
    id: root
    popoutName: "clip"
    title: "clipboard"
    popupWidth: 480
    popupHeight: 520

    ListModel { id: model }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: SplitParser {
            onRead: data => {
                if (data.length === 0) return
                const tab = data.indexOf("\t")
                const preview = tab >= 0 ? data.slice(tab + 1) : data
                model.append({ key: data, label: preview, subtitle: "", icon: "" })
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
        id: menu
        anchors.fill: parent
        active: root.open
        items: model
        emptyText: "clipboard is empty ✧"
        placeholder: "search clipboard..."

        onSelected: (item, action) => {
            Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "_", item.key])
            root.closeRequested()
        }
        onCloseRequested: root.closeRequested()
    }
}
