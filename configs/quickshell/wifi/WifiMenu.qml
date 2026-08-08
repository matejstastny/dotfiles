import QtQuick
import Quickshell
import Quickshell.Networking
import "../common"

PopupWindow {
    id: root
    popoutName: "wifimenu"
    title: "wifi"
    popupWidth: 420
    popupHeight: 520

    property var wifiDevice: null
    property var networkRows: []
    property string pendingSsid: ""
    property var pendingNetwork: null
    property string passwordError: ""

    function signalGlyph(strength) {
        const pct = strength <= 1.0 ? strength * 100 : strength
        if (pct >= 80) return "󰤨"
        if (pct >= 60) return "󰤥"
        if (pct >= 40) return "󰤢"
        if (pct >= 20) return "󰤟"
        return "󰤯"
    }

    function findWifiDevice() {
        let found = null
        for (const d of Networking.devices.values) {
            if (d.type === DeviceType.Wifi) { found = d; break }
        }
        root.wifiDevice = found
        root.refreshNetworkRows()
    }

    function refreshNetworkRows() {
        if (!root.wifiDevice) { root.networkRows = []; return }
        const nets = root.wifiDevice.networks.values.slice()
        nets.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            return (b.signalStrength || 0) - (a.signalStrength || 0)
        })
        root.networkRows = nets
    }

    function activate(network) {
        if (network.connected) {
            network.device.disconnect()
        } else if (network.known || network.security === WifiSecurityType.Open) {
            network.connect()
        } else {
            root.pendingSsid = network.name
            root.pendingNetwork = network
            root.passwordError = ""
            passwordField.clear()
            passwordField.focusInput()
        }
    }

    Connections {
        target: Networking.devices
        function onValuesChanged() { root.findWifiDevice() }
    }
    Connections {
        target: root.wifiDevice ? root.wifiDevice.networks : null
        function onValuesChanged() { root.refreshNetworkRows() }
    }
    Connections {
        target: root.pendingNetwork
        function onConnectionFailed(reason) {
            root.passwordError = "wrong password ✧"
        }
        function onConnectedChanged() {
            if (root.pendingNetwork && root.pendingNetwork.connected) {
                root.pendingSsid = ""
                root.pendingNetwork = null
            }
        }
    }

    Component.onCompleted: findWifiDevice()
    onOpenChanged: {
        if (open) {
            root.pendingSsid = ""
            root.pendingNetwork = null
            root.findWifiDevice()
        }
    }

    Timer {
        interval: 2500
        repeat: true
        running: root.open
        onTriggered: root.findWifiDevice()
    }

    // -- network list view --
    Item {
        anchors.fill: parent
        visible: root.pendingSsid.length === 0

        Row {
            id: actionRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 10

            IconButton {
                width: (actionRow.width - actionRow.spacing) / 2
                height: 44
                icon: "󰑐"
                label: "refresh"
                onClicked: {
                    if (root.wifiDevice && root.wifiDevice.scannerEnabled !== undefined) {
                        root.wifiDevice.scannerEnabled = false
                        rescanTimer.start()
                    }
                    root.refreshNetworkRows()
                }
            }
            IconButton {
                width: (actionRow.width - actionRow.spacing) / 2
                height: 44
                icon: Networking.wifiEnabled ? "󰖩" : "󰖪"
                label: Networking.wifiEnabled ? "on" : "off"
                active: Networking.wifiEnabled
                onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
            }
        }

        Timer {
            id: rescanTimer
            interval: 300
            onTriggered: if (root.wifiDevice) root.wifiDevice.scannerEnabled = true
        }

        Rectangle {
            id: divider
            anchors.top: actionRow.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: theme.muted
        }

        Text {
            id: caption
            anchors.top: divider.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            text: "networks"
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
            model: root.networkRows
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
                    color: cell.current ? Qt.rgba(theme.purple.r, theme.purple.g, theme.purple.b, 0.18) : "transparent"
                }

                Text {
                    id: sig
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.signalGlyph(cell.modelData.signalStrength)
                    color: cell.current ? theme.purple : theme.dim
                    font.pixelSize: 14
                    font.family: theme.fontFamily
                }

                Text {
                    id: statusPill
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: (cell.modelData.connected ? "connected" : (cell.modelData.known ? "saved" : ""))
                        + (cell.modelData.security !== WifiSecurityType.Open ? " 󰌾" : "")
                    color: cell.modelData.connected ? theme.purple : theme.dim
                    font.pixelSize: 10
                    font.family: theme.fontFamily
                }

                Text {
                    text: cell.modelData.name
                    color: cell.current ? theme.bright : theme.text
                    font.pixelSize: 13
                    font.family: theme.fontFamily
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: sig.right
                    anchors.leftMargin: 8
                    anchors.right: statusPill.left
                    anchors.rightMargin: 8
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { list.currentIndex = cell.index; root.activate(cell.modelData) }
                }
            }

            Keys.onReturnPressed: if (list.currentIndex >= 0) root.activate(root.networkRows[list.currentIndex])
            Keys.onEnterPressed: if (list.currentIndex >= 0) root.activate(root.networkRows[list.currentIndex])
            Keys.onEscapePressed: root.closeRequested()
            focus: root.open && root.pendingSsid.length === 0
        }

        Text {
            anchors.centerIn: list
            visible: root.networkRows.length === 0
            text: "no networks found ✧"
            color: theme.dim
            font.pixelSize: 12
            font.family: theme.fontFamily
        }
    }

    // -- inline password sub-view --
    Item {
        anchors.fill: parent
        visible: root.pendingSsid.length > 0

        Text {
            id: pwTitle
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            text: "🔒 password for " + root.pendingSsid
            color: theme.purple
            font.pixelSize: 13
            font.bold: true
            font.family: theme.fontFamily
            elide: Text.ElideRight
        }

        SearchField {
            id: passwordField
            anchors.top: pwTitle.bottom
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.right: parent.right
            placeholder: "password..."
            password: true

            onEscapePressed: {
                root.pendingSsid = ""
                root.pendingNetwork = null
            }
            onAccepted: {
                if (root.pendingNetwork && text.length > 0) {
                    root.passwordError = ""
                    root.pendingNetwork.connectWithPsk(text)
                }
            }
        }

        Text {
            anchors.top: passwordField.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            visible: root.passwordError.length > 0
            text: root.passwordError
            color: theme.rose
            font.pixelSize: 11
            font.family: theme.fontFamily
        }
    }
}
