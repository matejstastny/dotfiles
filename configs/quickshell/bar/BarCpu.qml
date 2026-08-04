import QtQuick
import Quickshell.Io

BarStat {
    id: root

    icon: "󰍛"
    title: "cpu"
    valueText: usage.toFixed(0).padStart(2, " ") + "%"
    lines: [usage.toFixed(1) + "% used"]

    property real usage: 0
    property real prevIdle: -1
    property real prevTotal: -1

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["sh", "-c", "grep '^cpu ' /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/).slice(1).map(Number)
                const idle = parts[3] + parts[4]
                const total = parts.reduce((a, b) => a + b, 0)
                if (root.prevTotal >= 0) {
                    const totalDiff = total - root.prevTotal
                    const idleDiff = idle - root.prevIdle
                    root.usage = totalDiff > 0 ? 100 * (1 - idleDiff / totalDiff) : 0
                    root.history = root.history.concat([root.usage]).slice(-30)
                }
                root.prevIdle = idle
                root.prevTotal = total
            }
        }
    }
}
