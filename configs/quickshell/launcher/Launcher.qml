import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

PopupWindow {
    id: root
    popoutName: "launcher"
    title: "launcher"
    implicitWidth: 560
    implicitHeight: 480

    readonly property string mruScript: Quickshell.env("HOME") + "/dotfiles/bin/launcher-touch"
    readonly property string mruFile: Quickshell.env("HOME") + "/.local/share/quickshell-launcher-mru"

    property var mruIds: []
    property var entries: []
    property var filteredRows: []

    function rebuildEntries() {
        const rows = []
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay) continue
            rows.push({
                label: e.name,
                subtitle: e.genericName || "",
                icon: e.icon,
                key: e.id,
                ref: e
            })
        }
        rows.sort((a, b) => {
            const ai = root.mruIds.indexOf(a.key)
            const bi = root.mruIds.indexOf(b.key)
            const ar = ai === -1 ? Infinity : ai
            const br = bi === -1 ? Infinity : bi
            if (ar !== br) return ar - br
            return a.label.localeCompare(b.label)
        })
        root.entries = rows
        root.refilter()
    }

    function refilter() {
        const query = search.text.toLowerCase()
        if (query.length === 0) {
            root.filteredRows = root.entries
        } else {
            root.filteredRows = root.entries.filter(e =>
                (e.label + " " + e.subtitle).toLowerCase().includes(query))
        }
        list.currentIndex = root.filteredRows.length > 0 ? 0 : -1
    }

    function launchCurrent() {
        if (list.currentIndex >= 0 && list.currentIndex < root.filteredRows.length) {
            const item = root.filteredRows[list.currentIndex]
            root.mruIds = [item.key].concat(root.mruIds.filter(id => id !== item.key))
            Quickshell.execDetached([root.mruScript, item.key])
            item.ref.execute()
            root.closeRequested()
        }
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { root.rebuildEntries() }
    }

    Process {
        id: mruLoader
        command: ["bash", "-c", "cat '" + root.mruFile + "' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.mruIds = text.split("\n").filter(l => l.length > 0)
                root.rebuildEntries()
            }
        }
    }

    Component.onCompleted: mruLoader.running = true

    onOpenChanged: {
        if (open) {
            search.clear()
            refilter()
            search.focusInput()
        }
    }

    SearchField {
        id: search
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        placeholder: "search apps..."
        onTextChanged: root.refilter()
        onUpPressed: list.decrementCurrentIndex()
        onDownPressed: list.incrementCurrentIndex()
        onEscapePressed: root.closeRequested()
        onAccepted: root.launchCurrent()
    }

    ListView {
        id: list
        anchors.top: search.bottom
        anchors.topMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        spacing: 2
        model: root.filteredRows
        boundsBehavior: Flickable.StopAtBounds
        keyNavigationWraps: true
        highlightMoveDuration: 60
        highlightMoveVelocity: -1

        delegate: Item {
            id: cell
            required property var modelData
            required property int index
            readonly property bool current: ListView.isCurrentItem
            width: list.width
            height: 44

            Rectangle {
                anchors.fill: parent
                radius: theme.radiusSmall
                color: cell.current ? Qt.rgba(theme.purple.r, theme.purple.g, theme.purple.b, 0.18) : "transparent"
            }

            Image {
                id: icon
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                height: 26
                source: Quickshell.iconPath(cell.modelData.icon, true)
                asynchronous: true
                smooth: true
            }

            Column {
                anchors.left: icon.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    text: cell.modelData.label
                    color: cell.current ? theme.bright : theme.text
                    font.pixelSize: 13
                    font.family: theme.fontFamily
                    elide: Text.ElideRight
                    width: parent.width
                }
                Text {
                    visible: text.length > 0
                    text: cell.modelData.subtitle
                    color: theme.dim
                    font.pixelSize: 10
                    font.family: theme.fontFamily
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { list.currentIndex = cell.index; root.launchCurrent() }
            }
        }
    }

    Text {
        anchors.centerIn: list
        visible: root.filteredRows.length === 0
        text: "no matches ✧"
        color: theme.dim
        font.pixelSize: 12
        font.family: theme.fontFamily
    }
}
