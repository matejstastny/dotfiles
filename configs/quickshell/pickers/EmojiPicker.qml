import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

PopupWindow {
    id: root
    popoutName: "emoji"
    title: "emoji"
    implicitWidth: 480
    implicitHeight: 520

    readonly property string dataFile: Quickshell.env("HOME") + "/dotfiles/configs/quickshell/pickers/data/emoji.json"

    ListModel { id: model }

    Process {
        id: lister
        command: ["cat", root.dataFile]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0) return
                const entries = JSON.parse(text)
                for (const e of entries) {
                    const kw = e.keywords.split(", ").slice(0, 3).join(", ")
                    model.append({ key: e.emoji, label: e.name, subtitle: kw, keywords: e.keywords, icon: e.emoji })
                }
            }
        }
    }

    onOpenChanged: {
        if (open && model.count === 0) lister.running = true
    }

    ListMenuPopup {
        anchors.fill: parent
        active: root.open
        items: model
        emptyText: "no emoji found ✧"
        placeholder: "search emoji..."

        onSelected: (item, action) => {
            Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | wl-copy", "_", item.key])
            root.closeRequested()
        }
        onCloseRequested: root.closeRequested()
    }
}
