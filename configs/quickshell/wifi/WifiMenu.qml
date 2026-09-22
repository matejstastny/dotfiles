import QtQuick
import Quickshell
import Quickshell.Networking
import "../"
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
    property bool scanning: false

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
        if (root.wifiDevice) root.wifiDevice.scannerEnabled = true
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

    function doScan() {
        if (!root.wifiDevice) return
        root.scanning = true
        root.refreshNetworkRows()
        scanIndicatorTimer.start()
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
        id: scanTimer
        interval: 5000
        repeat: true
        running: root.open && Networking.wifiEnabled
        onTriggered: root.doScan()
    }

    Timer {
        id: scanIndicatorTimer
        interval: 700
        onTriggered: root.scanning = false
    }

    // -- network list view --
    Item {
        anchors.fill: parent
        visible: root.pendingSsid.length === 0

        Text {
            id: caption
            anchors.top: parent.top
            anchors.left: parent.left
            text: "networks"
            color: Theme.dim
            font.pixelSize: 10
            font.family: Theme.fontMono
        }

        Text {
            id: scanIndicator
            anchors.verticalCenter: caption.verticalCenter
            anchors.right: parent.right
            visible: root.scanning
            text: "󰑐 refreshing…"
            color: Theme.purple
            font.pixelSize: 10
            font.family: Theme.fontMono
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
                    radius: Theme.radiusSmall
                    color: cell.current ? Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.18) : "transparent"
                }

                Text {
                    id: sig
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.signalGlyph(cell.modelData.signalStrength)
                    color: cell.current ? Theme.purple : Theme.dim
                    font.pixelSize: 14
                    font.family: Theme.fontMono
                }

                Text {
                    id: statusPill
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: (cell.modelData.connected ? "connected" : (cell.modelData.known ? "saved" : ""))
                        + (cell.modelData.security !== WifiSecurityType.Open ? " 󰌾" : "")
                    color: cell.modelData.connected ? Theme.purple : Theme.dim
                    font.pixelSize: 10
                    font.family: Theme.fontMono
                }

                Text {
                    text: cell.modelData.name
                    color: cell.current ? Theme.bright : Theme.text
                    font.pixelSize: 13
                    font.family: Theme.fontMono
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
            color: Theme.dim
            font.pixelSize: 12
            font.family: Theme.fontMono
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
            color: Theme.purple
            font.pixelSize: 13
            font.family: Theme.fontMono
            font.weight: Theme.weightHeading
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
            color: Theme.rose
            font.pixelSize: 11
            font.family: Theme.fontMono
        }
    }
}
