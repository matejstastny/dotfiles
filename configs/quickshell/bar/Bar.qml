import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"

PanelWindow {
    id: root

    signal clockClicked()

    readonly property Theme theme: Theme {}
    readonly property int barHeight: 35

    readonly property int atticHeight: 400

    color: "transparent"
    implicitHeight: barHeight + atticHeight
    exclusiveZone: barHeight

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    focusable: false

    anchors {
        top: true
        left: true
        right: true
    }

    mask: Region {
        item: barBg
        Region {
            item: cpuStat.hovered ? cpuStat.popoutItem : null
        }
        Region {
            item: memStat.hovered ? memStat.popoutItem : null
        }
        Region {
            item: diskStat.hovered ? diskStat.popoutItem : null
        }
        Region {
            item: netStat.hovered ? netStat.popoutItem : null
        }
    }

    Rectangle {
        id: barBg
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.barHeight
        color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.93)
    }

    Row {
        anchors.left: parent.left
        anchors.top: parent.top
        height: root.barHeight
        anchors.leftMargin: 10
        spacing: 8

        BarLogo {
            anchors.verticalCenter: parent.verticalCenter
        }

        BarSep { anchors.verticalCenter: parent.verticalCenter }

        BarWorkspaces {
            anchors.verticalCenter: parent.verticalCenter
            screen: root.screen
        }

        BarSep { anchors.verticalCenter: parent.verticalCenter }

        BarActiveWindow {
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.barHeight
        anchors.rightMargin: 10
        spacing: 8

        BarScriptModule {
            anchors.verticalCenter: parent.verticalCenter
            script: "/home/elara/dotfiles/bin/bar-recording"
            interval: 1000
            onClickCommand: "/home/elara/dotfiles/bin/record"
        }

        BarScriptModule {
            anchors.verticalCenter: parent.verticalCenter
            script: "/home/elara/dotfiles/bin/bar-tailscale"
            interval: 10000
            onClickCommand: "tailscale up"
        }
        BarScriptModule {
            anchors.verticalCenter: parent.verticalCenter
            script: "/home/elara/dotfiles/bin/bar-docker"
            interval: 5000
            onClickCommand: "kitty -e sh -c 'docker ps; read'"
        }

        BarSep { anchors.verticalCenter: parent.verticalCenter }

        BarNetwork { id: netStat; anchors.verticalCenter: parent.verticalCenter }
        BarCpu { id: cpuStat; anchors.verticalCenter: parent.verticalCenter }
        BarMemory { id: memStat; anchors.verticalCenter: parent.verticalCenter }
        BarDisk { id: diskStat; anchors.verticalCenter: parent.verticalCenter }

        BarSep { anchors.verticalCenter: parent.verticalCenter }

        BarVolume { anchors.verticalCenter: parent.verticalCenter }
        BarBattery { anchors.verticalCenter: parent.verticalCenter }

        BarSep { anchors.verticalCenter: parent.verticalCenter }

        BarClock {
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.clockClicked()
        }
    }
}
