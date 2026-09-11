import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

PopupWindow {
    id: root
    popoutName: "keyboard"
    title: "keyboard"
    popupWidth: 340
    popupHeight: 220

    readonly property var layouts: [
        { key: "us", label: "english", subtitle: "us" },
        { key: "cz", label: "czech (qwerty)", subtitle: "cz" }
    ]

    ListModel { id: model }

    function refresh() {
        model.clear()
        for (let i = 0; i < root.layouts.length; i++) {
            const l = root.layouts[i]
            model.append({ key: l.key, layoutIndex: i, label: l.label, subtitle: l.subtitle, icon: "󰌌" })
        }
    }

    Process {
        id: activeCheck
        command: ["bash", "-c", "hyprctl devices -j | jq -r '.keyboards[0].active_keymap'"]
        stdout: SplitParser {
            onRead: data => {
                const active = data.trim().toLowerCase()
                for (let i = 0; i < model.count; i++) {
                    const row = model.get(i)
                    model.setProperty(i, "subtitle", active.includes(row.key) ? "active" : row.key)
                }
            }
        }
    }

    onOpenChanged: {
        if (open) {
            root.refresh()
            activeCheck.running = true
        }
    }

    ListMenuPopup {
        anchors.fill: parent
        active: root.open
        mode: "list"
        items: model
        placeholder: "switch layout..."

        onSelected: (item) => {
            Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", item.layoutIndex.toString()])
            root.closeRequested()
        }
        onCloseRequested: root.closeRequested()
    }
}
