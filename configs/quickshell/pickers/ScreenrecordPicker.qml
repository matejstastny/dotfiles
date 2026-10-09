import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../common"

CommandPicker {
    id: root

    popoutName: "screenrecord"
    placeholder: "recordings"
    emptyText: "no recordings"

    readonly property string recDir: Quickshell.env("HOME") + "/pictures/screenrecord"

    actions: [
        {
            key: "copy",
            code: Qt.Key_D,
            hint: "alt+d  copy"
        }
    ]

    property var recordings: []

    Process {
        id: lister
        command: ["bash", "-c", "ls -t '" + root.recDir + "' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    if (line.length === 0)
                        continue;
                    out.push({ key: line, label: line, icon: "󰃽" });
                }
                root.recordings = out;
            }
        }
    }

    rows: root.recordings

    onOpenChanged: if (root.open)
        lister.running = true

    onSelected: (item, action) => {
        if (action === "copy")
            Quickshell.execDetached(["bash", "-c", "printf 'file://%s' \"$1\" | wl-copy --type text/uri-list", "_", root.recDir + "/" + item.key]);
        else
            Quickshell.execDetached(["mpv", root.recDir + "/" + item.key]);
        root.closeRequested();
    }
}
