import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    signal clockClicked()

    readonly property Theme theme: Theme {}
    readonly property int barHeight: 38

    color: "transparent"
    implicitHeight: barHeight + 220
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

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.barHeight
        color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.75)
    }

    Item {
        anchors.left: parent.left
        anchors.top: parent.top
        height: root.barHeight
        anchors.leftMargin: 10

        BarWorkspaces {
            anchors.verticalCenter: parent.verticalCenter
            screen: root.screen
        }
    }

    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.barHeight
        anchors.rightMargin: 10
        spacing: 12

        BarScriptModule {
            anchors.verticalCenter: parent.verticalCenter
            script: "/home/elara/dotfiles/bin/bar-recording"
            interval: 1000
            onClickCommand: "/home/elara/dotfiles/bin/record"
        }

        BarTray {
            anchors.verticalCenter: parent.verticalCenter
        }

        BarSep { anchors.verticalCenter: parent.verticalCenter }

        BarCpu { anchors.verticalCenter: parent.verticalCenter }
        BarMemory { anchors.verticalCenter: parent.verticalCenter }
        BarDisk { anchors.verticalCenter: parent.verticalCenter }

        BarSep { anchors.verticalCenter: parent.verticalCenter }

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

        BarVolume { anchors.verticalCenter: parent.verticalCenter }
        BarBattery { anchors.verticalCenter: parent.verticalCenter }

        BarSep { anchors.verticalCenter: parent.verticalCenter }

        BarClock {
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.clockClicked()
        }
    }
}
