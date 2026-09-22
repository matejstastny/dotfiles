import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../common"

PopupWindow {
    id: root
    popoutName: "clip"
    title: "clipboard"
    popupWidth: 520
    popupHeight: 540

    ListModel { id: model }

    function isImage(preview) {
        return /^\[\[ binary data .* \d+x\d+ \]\]$/i.test(preview)
    }

    function imageType(preview) {
        const match = preview.match(/(\d+)x(\d+) \]\]$/i)
        return match ? match[1] + " × " + match[2] : "IMAGE"
    }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: SplitParser {
            onRead: data => {
                if (data.length === 0) return
                const tab = data.indexOf("\t")
                const preview = tab >= 0 ? data.slice(tab + 1) : data
                const image = root.isImage(preview)
                model.append({
                    key: data,
                    label: image ? "Image in clipboard" : preview.replace(/\s+/g, " ").trim(),
                    subtitle: image ? root.imageType(preview) : "",
                    image: image
                })
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
        rowDelegate: clipRow

        onSelected: (item, action) => {
            Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "_", item.key])
            root.closeRequested()
        }
        onCloseRequested: root.closeRequested()
    }

    Component {
        id: clipRow

        Item {
            id: row
            required property var modelData
            required property int index

            readonly property bool current: ListView.isCurrentItem
            readonly property bool imageClip: modelData.image

            width: ListView.view ? ListView.view.width : 400
            height: 46

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusSmall
                color: row.current ? Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.18) : "transparent"
                border.width: row.current ? 1 : 0
                border.color: Theme.purple
                Behavior on color { ColorAnimation { duration: 100 } }
            }

            Rectangle {
                id: marker
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                radius: Theme.radiusSmall
                color: row.imageClip
                    ? Qt.rgba(Theme.rose.r, Theme.rose.g, Theme.rose.b, 0.16)
                    : Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.12)

                Text {
                    anchors.centerIn: parent
                    text: row.imageClip ? "▧" : "›"
                    color: row.imageClip ? Theme.rose : (row.current ? Theme.purple : Theme.dim)
                    font.pixelSize: row.imageClip ? 16 : 22
                    font.family: Theme.fontMono
                }
            }

            Text {
                anchors.left: marker.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: row.imageClip ? 68 : 12
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.label
                color: row.current ? Theme.bright : Theme.text
                font.pixelSize: 13
                font.family: Theme.fontMono
                elide: Text.ElideRight
            }

            Text {
                visible: row.imageClip
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.subtitle
                color: row.current ? Theme.rose : Theme.dim
                font.pixelSize: 10
                font.family: Theme.fontMono
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    ListView.view.currentIndex = row.index
                    menu.activateCurrent()
                }
            }
        }
    }
}
