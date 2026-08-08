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
                Quickshell.execDetached([Quickshell.env("HOME") + "/dotfiles/bin/capture-to-todo"])
            } else if (text.length > 0) {
                Quickshell.execDetached([Quickshell.env("HOME") + "/dotfiles/bin/capture-note", text])
            }
            root.closeRequested()
        }
        onCloseRequested: root.closeRequested()
    }
}
