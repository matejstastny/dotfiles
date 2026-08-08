import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

PopupWindow {
    id: root
    popoutName: "todo"
    implicitWidth: 480
    implicitHeight: 520

    property string profile: "personal"
    readonly property string label: root.profile === "stars" ? "stars" : "personal"
    readonly property string file: Quickshell.env("HOME") + "/notes/todo/" + root.profile + ".md"

    title: root.label

    ListModel { id: model }

    Process {
        id: lister
        command: ["bash", "-c",
            "mkdir -p ~/notes/todo; " +
            "[ -f '" + root.file + "' ] || printf '#todo #" + root.profile + "\\n\\n' > '" + root.file + "'; " +
            "grep '^- \\[ \\]' '" + root.file + "' 2>/dev/null | sed 's/^- \\[ \\] //'"]
        stdout: SplitParser {
            onRead: data => {
                if (data.length === 0) return
                model.append({ key: data, label: data, subtitle: "", icon: "☐" })
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
        mode: "listOrFreeText"
        items: model
        emptyText: "nothing open ✧"
        placeholder: "select or type a new todo..."

        onSelected: (item, action) => {
            Quickshell.execDetached([Quickshell.env("HOME") + "/dotfiles/bin/todo-mark-done", root.file, item.key])
            root.closeRequested()
        }
        onFreeTextSubmitted: text => {
            Quickshell.execDetached([Quickshell.env("HOME") + "/dotfiles/bin/todo-add", root.file, text])
            root.closeRequested()
        }
        onCloseRequested: root.closeRequested()
    }
}
