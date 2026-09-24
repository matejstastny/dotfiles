import QtQuick
import Quickshell
import "../common"

PopupWindow {
    id: root
    popoutName: "capture"
    title: "capture"
    popupWidth: 480
    popupHeight: 130

    ListMenuPopup {
        anchors.fill: parent
        active: root.open
        mode: "freeText"
        placeholder: "quick note..."
        secondaryActionKey: "todo"
        secondaryActionHint: "Alt+Backspace last capture → todo"

        onFreeTextSubmitted: (text, action) => {
            if (action === "todo") {
                Quickshell.execDetached([Quickshell.env("HOME") + "/dotfiles/scripts/capture-to-todo.sh"])
            } else if (text.length > 0) {
                Quickshell.execDetached([Quickshell.env("HOME") + "/dotfiles/scripts/capture-note.sh", text])
            }
            root.closeRequested()
        }
        onCloseRequested: root.closeRequested()
    }
}
