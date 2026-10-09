import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../"
import "../common"

CommandPicker {
    id: root

    popoutName: "bluetoothmenu"
    placeholder: "bluetooth"

    // listOrFreeText purely so alt+s still reaches a handler when the filter
    // has left no row selected to hang the action off
    mode: "listOrFreeText"

    // connecting / paired / battery is live state on every row
    quietSubtitles: false

    emptyText: root.adapter && root.adapter.discovering ? "scanning…" : "no devices"

    notice: !root.adapter ? "no adapter found" : (!root.adapter.enabled ? "bluetooth is off" : "")

    actions: [
        {
            key: "scan",
            code: Qt.Key_S,
            hint: root.adapter && root.adapter.discovering ? "alt+s  stop scanning" : "alt+s  scan"
        },
        {
            // forget used to be a button that appeared on hover, which is no
            // use at all to a keyboard
            key: "forget",
            code: Qt.Key_Backspace,
            hint: "alt+backspace  forget"
        }
    ]

    readonly property var adapter: Bluetooth.defaultAdapter
    property var deviceRows: []

    function rank(d: var): int {
        if (d.connected)
            return 0;
        if (d.paired)
            return 1;
        return 2;
    }

    function statusText(d: var): string {
        if (d.pairing)
            return "pairing…";
        if (d.state === BluetoothDeviceState.Connecting)
            return "connecting…";
        if (d.state === BluetoothDeviceState.Disconnecting)
            return "disconnecting…";
        if (d.connected)
            return "connected" + (d.batteryAvailable ? "  " + Math.round(d.battery * 100) + "%" : "");
        if (d.paired)
            return "paired";
        return "new";
    }

    function refreshDeviceRows(): void {
        const scanning = root.adapter && root.adapter.discovering;
        const devices = Bluetooth.devices.values.filter(d => d.name.length > 0 && (d.paired || scanning));
        devices.sort((a, b) => {
            const r = root.rank(a) - root.rank(b);
            return r !== 0 ? r : a.name.localeCompare(b.name);
        });
        const out = [];
        for (const d of devices)
            out.push({
                key: d.address ?? d.name,
                label: d.name,
                icon: d.connected ? "󰂱" : "󰂯",
                subtitle: root.statusText(d),
                highlighted: d.connected,
                ref: d
            });
        root.deviceRows = out;
    }

    function primaryAction(d: var): void {
        if (d.pairing || d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting)
            return;
        if (!d.paired) {
            d.pair();
            return;
        }
        if (d.connected)
            d.disconnect();
        else
            d.connect();
    }

    rows: root.deviceRows

    Connections {
        target: Bluetooth.devices
        function onValuesChanged() {
            root.refreshDeviceRows();
        }
    }

    Connections {
        target: root.adapter
        function onDiscoveringChanged() {
            root.refreshDeviceRows();
        }
        function onEnabledChanged() {
            root.refreshDeviceRows();
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.open
        onTriggered: root.refreshDeviceRows()
    }

    Component.onCompleted: root.refreshDeviceRows()

    onOpenChanged: {
        if (root.open)
            root.refreshDeviceRows();
        else if (root.adapter && root.adapter.discovering)
            root.adapter.discovering = false;
    }

    onSelected: (item, action) => {
        if (action === "scan") {
            if (root.adapter && root.adapter.enabled)
                root.adapter.discovering = !root.adapter.discovering;
            return;
        }
        if (action === "forget") {
            if (item.ref.paired)
                item.ref.forget();
            return;
        }
        root.primaryAction(item.ref);
    }

    // alt+s has to work with nothing selected too, which `selected` cannot do
    onFreeTextSubmitted: (text, action) => {
        if (action === "scan" && root.adapter && root.adapter.enabled)
            root.adapter.discovering = !root.adapter.discovering;
    }
}
