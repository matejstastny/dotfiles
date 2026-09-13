import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../common"

PopupWindow {
    id: root
    popoutName: "bluetoothmenu"
    title: "bluetooth"
    popupWidth: 420
    popupHeight: 500

    readonly property var adapter: Bluetooth.defaultAdapter
    property var deviceRows: []

    function rank(d) {
        if (d.connected) return 0
        if (d.paired) return 1
        return 2
    }

    function refreshDeviceRows() {
        const scanning = root.adapter && root.adapter.discovering
        const rows = Bluetooth.devices.values.filter(d => d.name.length > 0 && (d.paired || scanning))
        rows.sort((a, b) => {
            const r = root.rank(a) - root.rank(b)
            return r !== 0 ? r : a.name.localeCompare(b.name)
        })
        root.deviceRows = rows
    }

    function statusText(d) {
        if (d.pairing) return "pairing…"
        if (d.state === BluetoothDeviceState.Connecting) return "connecting…"
        if (d.state === BluetoothDeviceState.Disconnecting) return "disconnecting…"
        if (d.connected) return "connected" + (d.batteryAvailable ? "  " + Math.round(d.battery * 100) + "%" : "")
        if (d.paired) return "paired"
        return "new"
    }

    function primaryAction(d) {
        if (d.pairing || d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting) return
        if (!d.paired) { d.pair(); return }
        if (d.connected) d.disconnect()
        else d.connect()
    }

    function forget(d) { d.forget() }

    Connections {
        target: Bluetooth.devices
        function onValuesChanged() { root.refreshDeviceRows() }
    }
    Connections {
        target: root.adapter
        function onDiscoveringChanged() { root.refreshDeviceRows() }
        function onEnabledChanged() { root.refreshDeviceRows() }
    }

    Component.onCompleted: refreshDeviceRows()
    onOpenChanged: {
        if (open) root.refreshDeviceRows()
        else if (root.adapter && root.adapter.discovering) root.adapter.discovering = false
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.open
        onTriggered: root.refreshDeviceRows()
    }

    Text {
        id: caption
        anchors.top: parent.top
        anchors.left: parent.left
        text: !root.adapter ? "no adapter found ✧"
            : (!root.adapter.enabled ? "bluetooth is off" : "paired & nearby devices")
        color: theme.dim
        font.pixelSize: 10
        font.family: theme.fontFamily
    }

    Text {
        id: scanIndicator
        anchors.verticalCenter: caption.verticalCenter
        anchors.right: parent.right
        visible: root.adapter && root.adapter.enabled
        text: root.adapter && root.adapter.discovering ? "󰑐 scanning…" : "alt+s scan"
        color: root.adapter && root.adapter.discovering ? theme.purple : theme.dim
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
            opacity: cell.modelData.paired ? 1.0 : 0.7

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
                anchors.right: (forgetBtn.visible && rowMouse.containsMouse) ? forgetBtn.left : parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: root.statusText(cell.modelData)
                color: (cell.modelData.connected || cell.modelData.pairing) ? theme.purple : theme.dim
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
                anchors.right: statusPill.left
                anchors.rightMargin: 8
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    list.currentIndex = cell.index
                    root.primaryAction(cell.modelData)
                }
            }

            Item {
                id: forgetBtn
                visible: cell.modelData.paired
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                height: 20
                opacity: rowMouse.containsMouse ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "forget"
                    color: theme.rose
                    font.pixelSize: 9
                    font.family: theme.fontFamily
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.forget(cell.modelData)
                }
            }
        }

        Keys.onReturnPressed: if (list.currentIndex >= 0) root.primaryAction(root.deviceRows[list.currentIndex])
        Keys.onEscapePressed: root.closeRequested()
        Keys.onPressed: event => {
            if ((event.modifiers & Qt.AltModifier) && event.key === Qt.Key_S) {
                if (root.adapter && root.adapter.enabled) root.adapter.discovering = !root.adapter.discovering
                event.accepted = true
            }
        }
        focus: root.open
    }

    Text {
        anchors.centerIn: list
        visible: root.deviceRows.length === 0
        text: root.adapter && root.adapter.discovering ? "scanning…" : "no devices ✧"
        color: theme.dim
        font.pixelSize: 12
        font.family: theme.fontFamily
    }
}
