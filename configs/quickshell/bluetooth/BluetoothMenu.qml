import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../common"

PopupWindow {
    id: root
    popoutName: "bluetoothmenu"
    title: "bluetooth"
    implicitWidth: 420
    implicitHeight: 420

    property var deviceRows: []

    function refreshDeviceRows() {
        const rows = Bluetooth.devices.values.filter(d => d.paired)
        rows.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            return a.name.localeCompare(b.name)
        })
        root.deviceRows = rows
    }

    Connections {
        target: Bluetooth.devices
        function onValuesChanged() { root.refreshDeviceRows() }
    }

    Component.onCompleted: refreshDeviceRows()
    onOpenChanged: {
        if (open) root.refreshDeviceRows()
    }

    Text {
        id: caption
        anchors.top: parent.top
        anchors.left: parent.left
        text: "paired devices"
        color: theme.dim
        font.pixelSize: 10
        font.family: theme.fontFamily
    }

    ListView {
        id: list
        anchors.top: caption.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        spacing: 2
        model: root.deviceRows
        boundsBehavior: Flickable.StopAtBounds
        keyNavigationEnabled: true
        keyNavigationWraps: true
        highlightMoveDuration: 60
        highlightMoveVelocity: -1

        delegate: Item {
            id: cell
            required property var modelData
            required property int index
            readonly property bool current: ListView.isCurrentItem
            width: list.width
            height: 40

            Rectangle {
                anchors.fill: parent
                radius: theme.radiusSmall
                color: cell.modelData.connected
                    ? Qt.rgba(theme.purple.r, theme.purple.g, theme.purple.b, cell.current ? 0.28 : 0.16)
                    : (cell.current ? Qt.rgba(theme.purple.r, theme.purple.g, theme.purple.b, 0.18) : "transparent")
                border.width: cell.modelData.connected ? theme.borderWidth : 0
                border.color: theme.purple
            }

            Text {
                id: icon
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: cell.modelData.connected ? "󰂱" : "󰂯"
                color: cell.modelData.connected ? theme.purple : theme.dim
                font.pixelSize: cell.modelData.connected ? 16 : 14
                font.family: theme.fontFamily
            }

            Text {
                id: statusPill
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: (cell.modelData.connected ? "connected" : "")
                    + (cell.modelData.batteryAvailable ? "  " + Math.round(cell.modelData.battery * 100) + "%" : "")
                color: cell.modelData.connected ? theme.purple : theme.dim
                font.pixelSize: 10
                font.bold: cell.modelData.connected
                font.family: theme.fontFamily
            }

            Text {
                text: cell.modelData.name
                color: cell.modelData.connected ? theme.bright : (cell.current ? theme.bright : theme.text)
                font.pixelSize: 13
                font.bold: cell.modelData.connected
                font.family: theme.fontFamily
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: icon.right
                anchors.leftMargin: 8
                anchors.right: statusPill.text.length > 0 ? statusPill.left : parent.right
                anchors.rightMargin: 8
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    list.currentIndex = cell.index
                    cell.modelData.connected = !cell.modelData.connected
                    root.closeRequested()
                }
            }
        }

        Keys.onReturnPressed: if (list.currentIndex >= 0) {
            const d = root.deviceRows[list.currentIndex]
            d.connected = !d.connected
            root.closeRequested()
        }
        Keys.onEscapePressed: root.closeRequested()
        focus: root.open
    }

    Text {
        anchors.centerIn: list
        visible: root.deviceRows.length === 0
        text: "no paired devices ✧"
        color: theme.dim
        font.pixelSize: 12
        font.family: theme.fontFamily
    }
}
