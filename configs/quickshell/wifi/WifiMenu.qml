import QtQuick
import Quickshell
import Quickshell.Networking
import "../"
import "../common"

// two bodies in one drawer, and both of them are the same prompt: the network
// list, and the password line you get when a closed network wants one. there is
// no second kind of text field and no dialog - the list is replaced in place
CommandPicker {
    id: root

    popoutName: "wifimenu"

    readonly property bool prompting: root.pendingSsid.length > 0

    property var wifiDevice: null
    property var networkRows: []
    property string pendingSsid: ""
    property var pendingNetwork: null
    property string passwordError: ""
    property bool scanning: false

    function signalGlyph(strength: real): string {
        const pct = strength <= 1.0 ? strength * 100 : strength;
        if (pct >= 80)
            return "󰤨";
        if (pct >= 60)
            return "󰤥";
        if (pct >= 40)
            return "󰤢";
        if (pct >= 20)
            return "󰤟";
        return "󰤯";
    }

    function findWifiDevice(): void {
        let found = null;
        for (const d of Networking.devices.values) {
            if (d.type === DeviceType.Wifi) {
                found = d;
                break;
            }
        }
        root.wifiDevice = found;
        if (root.wifiDevice)
            root.wifiDevice.scannerEnabled = true;
        root.refreshNetworkRows();
    }

    function refreshNetworkRows(): void {
        if (!root.wifiDevice) {
            root.networkRows = [];
            return;
        }
        const nets = root.wifiDevice.networks.values.slice();
        nets.sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            return (b.signalStrength || 0) - (a.signalStrength || 0);
        });
        const out = [];
        for (const n of nets)
            out.push({
                key: n.name,
                label: n.name,
                icon: root.signalGlyph(n.signalStrength),
                subtitle: (n.connected ? "connected" : (n.known ? "saved" : "")) + (n.security !== WifiSecurityType.Open ? " 󰌾" : ""),
                highlighted: n.connected,
                ref: n
            });
        root.networkRows = out;
    }

    function doScan(): void {
        if (!root.wifiDevice)
            return;
        root.scanning = true;
        root.refreshNetworkRows();
        scanIndicatorTimer.start();
    }

    function activate(network: var): void {
        if (network.connected) {
            network.device.disconnect();
        } else if (network.known || network.security === WifiSecurityType.Open) {
            root.pendingNetwork = network;
            network.connect();
        } else {
            root.pendingSsid = network.name;
            root.pendingNetwork = network;
            root.passwordError = "";
        }
    }

    function cancelPrompt(): void {
        root.pendingSsid = "";
        root.pendingNetwork = null;
        root.passwordError = "";
    }

    Connections {
        target: Networking.devices
        function onValuesChanged() {
            root.findWifiDevice();
        }
    }

    Connections {
        target: root.wifiDevice ? root.wifiDevice.networks : null
        function onValuesChanged() {
            root.refreshNetworkRows();
        }
    }

    Connections {
        target: root.pendingNetwork
        function onConnectionFailed(reason) {
            if (reason !== ConnectionFailReason.NoSecrets)
                return;
            const alreadyPrompting = root.pendingSsid.length > 0;
            root.pendingSsid = root.pendingNetwork.name;
            root.passwordError = alreadyPrompting ? "wrong password" : "";
            if (root.view)
                root.view.reset();
        }
        function onConnectedChanged() {
            if (root.pendingNetwork && root.pendingNetwork.connected)
                root.cancelPrompt();
        }
    }

    Component.onCompleted: root.findWifiDevice()

    onOpenChanged: {
        if (root.open) {
            root.cancelPrompt();
            root.findWifiDevice();
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

    body: Component {
        Item {
            id: wifiBody

            implicitWidth: root.surfaceWidth
            implicitHeight: root.prompting ? password.implicitHeight : networks.implicitHeight

            CommandList {
                id: networks

                anchors.fill: parent
                visible: !root.prompting
                active: root.open && !root.prompting

                rows: root.networkRows
                placeholder: "wifi"
                emptyText: "no networks"
                // connected / saved is live state, not an explanation of the row
                // the cursor happens to be on
                quietSubtitles: false
                notice: root.scanning ? "󰑐 refreshing…" : ""

                Component.onCompleted: if (!root.prompting)
                    root.view = networks

                onSelected: item => root.activate(item.ref)
                onCloseRequested: root.closeRequested()
            }

            CommandList {
                id: password

                anchors.fill: parent
                visible: root.prompting
                active: root.open && root.prompting

                mode: "freeText"
                password: true
                placeholder: "󰌾 password for " + root.pendingSsid
                notice: root.passwordError

                onFreeTextSubmitted: text => {
                    if (root.pendingNetwork && text.length > 0) {
                        root.passwordError = "";
                        root.pendingNetwork.connectWithPsk(text);
                    }
                }
                // escape backs out to the list rather than closing the surface
                onCloseRequested: root.cancelPrompt()
            }

            // whichever body is up owns the prompt, so a picker-level reset or
            // query read reaches the right one
            Connections {
                target: root
                function onPromptingChanged() {
                    root.view = root.prompting ? password : networks;
                }
            }
        }
    }
}
