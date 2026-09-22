import QtQuick
import Quickshell
import "../"
import "../common"

// content only - lives in the right-hand drawer of Surface's blob field.
// a narrow column of big icons rather than a dialog of labelled ones, so the
// whole thing can slide out of the outline without covering the screen
Item {
    id: root

    property bool open: false
    signal closeRequested()

    property int currentIndex: 0

    readonly property int buttonSize: 80
    readonly property int padding: 20

    readonly property var actions: [
        { icon: "󰌾", danger: false, cmd: [Quickshell.env("HOME") + "/dotfiles/bin/lock"] },
        { icon: "󰒲", danger: false, cmd: ["systemctl", "suspend"] },
        { icon: "󰜉", danger: true, cmd: ["systemctl", "reboot"] },
        { icon: "󰐥", danger: true, cmd: ["systemctl", "poweroff"] }
    ]

    // the kuru kuru splits the column after suspend, so the two destructive
    // actions end up on their own side of it
    readonly property int spinnerAfter: 1

    // the drawer rests against the outline's inner wall, and the band reads as
    // part of the same surface, so it already supplies that much of the gap on
    // the right - matching it here would leave the icons sitting off-centre
    implicitWidth: root.padding + root.buttonSize + Math.max(root.padding - Theme.frameThickness, 0)
    implicitHeight: column.implicitHeight + root.padding * 2

    function fire(index: int): void {
        Quickshell.execDetached(root.actions[index].cmd);
        root.closeRequested();
    }

    onOpenChanged: {
        if (root.open) {
            root.currentIndex = 0;
            keys.forceActiveFocus();
        }
    }

    Item {
        id: keys

        anchors.fill: parent
        focus: root.open

        Keys.onUpPressed: root.currentIndex = Math.max(0, root.currentIndex - 1)
        Keys.onDownPressed: root.currentIndex = Math.min(root.actions.length - 1, root.currentIndex + 1)
        Keys.onEscapePressed: root.closeRequested()
        Keys.onReturnPressed: root.fire(root.currentIndex)
        Keys.onEnterPressed: root.fire(root.currentIndex)

        Column {
            id: column

            anchors.left: parent.left
            anchors.leftMargin: root.padding
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            Repeater {
                model: root.actions

                delegate: Column {
                    id: entry

                    required property var modelData
                    required property int index

                    spacing: column.spacing

                    IconButton {
                        implicitWidth: root.buttonSize
                        implicitHeight: root.buttonSize
                        icon: entry.modelData.icon
                        iconSize: 30
                        danger: entry.modelData.danger
                        active: entry.index === root.currentIndex
                        onClicked: root.fire(entry.index)
                    }

                    AnimatedImage {
                        width: root.buttonSize
                        height: root.buttonSize
                        visible: entry.index === root.spinnerAfter
                        playing: visible
                        asynchronous: true
                        speed: 0.7
                        fillMode: AnimatedImage.PreserveAspectFit
                        source: "file://" + Quickshell.env("HOME") + "/dotfiles/assets/kurukuru.gif"
                    }
                }
            }
        }
    }
}
