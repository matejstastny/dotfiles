import QtQuick
import Quickshell.Io

BarStat {
    id: root

    icon: "󰖩"
    title: "network"
    valueText: root.rateText
    lines: [root.downText, root.upText, root.connName]
    fillPct: 0

    property real rxRate: 0
    property real txRate: 0
    property real prevRx: -1
    property real prevTx: -1
    property string connName: "—"
    property string rateText: "…"
    property string downText: ""
    property string upText: ""

    readonly property int pollInterval: 2000
    readonly property real historyCapBytes: 5 * 1024 * 1024

    function fmtRate(bytesPerSec) {
        if (bytesPerSec >= 1024 * 1024) return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s"
        if (bytesPerSec >= 1024) return (bytesPerSec / 1024).toFixed(0) + " KB/s"
        return bytesPerSec.toFixed(0) + " B/s"
    }

    Timer {
        interval: root.pollInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["/home/elara/dotfiles/bin/bar-network"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split("|")
                if (parts.length < 4) return
                const rx = Number(parts[1])
                const tx = Number(parts[2])
                root.connName = parts[3]

                if (root.prevRx >= 0) {
                    const seconds = root.pollInterval / 1000
                    root.rxRate = Math.max(0, (rx - root.prevRx) / seconds)
                    root.txRate = Math.max(0, (tx - root.prevTx) / seconds)
                    const pct = Math.min(100, (root.rxRate / root.historyCapBytes) * 100)
                    root.history = root.history.concat([pct]).slice(-30)
                }
                root.prevRx = rx
                root.prevTx = tx

                root.downText = "↓ " + root.fmtRate(root.rxRate)
                root.upText = "↑ " + root.fmtRate(root.txRate)
                root.rateText = root.fmtRate(root.rxRate)
            }
        }
    }
}
