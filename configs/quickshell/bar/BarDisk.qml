import QtQuick
import Quickshell.Io

BarStat {
    id: root

    icon: "󰋊"
    title: "disk (/)"
    valueText: percent.toFixed(0) + "%"
    lines: [usedStr + " / " + totalStr]

    property real percent: 0
    property string usedStr: ""
    property string totalStr: ""

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["sh", "-c", "df -h / | tail -1 | awk '{print $3, $2, $5}'"]
        stdout: SplitParser {
            onRead: data => {
                const [used, total, pct] = data.trim().split(/\s+/)
                root.usedStr = used
                root.totalStr = total
                root.percent = parseFloat(pct) || 0
                root.history = root.history.concat([root.percent]).slice(-30)
            }
        }
    }
}
