import QtQuick
import Quickshell
import "../"
import "../common"

CommandPicker {
    id: root

    popoutName: "capture"
    mode: "freeText"
    placeholder: "quick note"

    actions: [
        {
            key: "todo",
            code: Qt.Key_Backspace,
            hint: "alt+backspace  last capture → todo"
        }
    ]

    onFreeTextSubmitted: (text, action) => {
        if (action === "todo")
            Quickshell.execDetached([Quickshell.env("HOME") + "/dotfiles/scripts/capture-to-todo.sh"]);
        else if (text.trim().length > 0)
            Quickshell.execDetached([Quickshell.env("HOME") + "/dotfiles/scripts/capture-note.sh", text]);
        root.closeRequested();
    }
}
