import QtQuick
import Quickshell.Io

BarStat {
    id: root

    icon: "󰘚"
    title: "memory"
    valueText: percent.toFixed(0) + "%"
    lines: [usedGb.toFixed(1) + "G / " + totalGb.toFixed(1) + "G"]

    property real percent: 0
    property real usedGb: 0
    property real totalGb: 0

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["awk", "/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{print t, a}", "/proc/meminfo"]
        stdout: SplitParser {
            onRead: data => {
                const [totalKb, availKb] = data.trim().split(/\s+/).map(Number)
                root.totalGb = totalKb / 1024 / 1024
                const availGb = availKb / 1024 / 1024
                root.usedGb = root.totalGb - availGb
                root.percent = root.totalGb > 0 ? (root.usedGb / root.totalGb) * 100 : 0
                root.history = root.history.concat([root.percent]).slice(-30)
            }
        }
    }
}
