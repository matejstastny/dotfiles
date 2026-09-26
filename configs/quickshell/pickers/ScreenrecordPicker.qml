import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

PopupWindow {
    id: root
    popoutName: "screenrecord"
    title: "recordings"
    popupWidth: 480
    popupHeight: 520

    readonly property string recDir: Quickshell.env("HOME") + "/pictures/screenrecord"

    ListModel { id: model }

    Process {
        id: lister
        command: ["bash", "-c", "ls -t '" + root.recDir + "' 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                if (data.length === 0) return
                model.append({ key: data, label: data, subtitle: "", icon: "󰃽" })
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
        emptyText: "no recordings found ✧"
        placeholder: "search recordings..."

        tertiaryActionKey: "copy"
        tertiaryActionHint: "Alt+D copy"

        onSelected: (item, action) => {
            if (action === "copy") {
                Quickshell.execDetached(["bash", "-c", "printf 'file://%s' \"$1\" | wl-copy --type text/uri-list", "_", root.recDir + "/" + item.key])
            } else {
                Quickshell.execDetached(["mpv", root.recDir + "/" + item.key])
            }
            root.closeRequested()
        }
        onCloseRequested: root.closeRequested()
    }
}
