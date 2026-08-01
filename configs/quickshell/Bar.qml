import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    signal clockClicked()

    readonly property Theme theme: Theme {}
    readonly property int barHeight: 38

    readonly property int atticHeight: 400

    color: "transparent"
    implicitHeight: barHeight + atticHeight
    exclusiveZone: barHeight

    readonly property bool trayMenuOpen: PopoutState.current.startsWith("traymenu")
    readonly property bool anyPopoutOpen: trayMenuOpen || cpuStat.hovered || memStat.hovered || diskStat.hovered

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:bar"
    // only becomes keyboard-interactive while a tray menu's HyprlandFocusGrab
    // needs it - never grabs focus just for normal bar interaction
    WlrLayershell.keyboardFocus: trayMenuOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    focusable: trayMenuOpen

    anchors {
        top: true
        left: true
        right: true
    }

    // this window is taller than the visible bar strip so popouts have room
    // to draw into, but a Wayland surface accepts input across its whole
    // rectangle by default - without this mask, that entire extra "attic"
    // area silently eats clicks meant for whatever's underneath, even when
    // nothing is visibly open there
    mask: Region {
        item: barBg
        Region {
            item: atticArea
        }
    }

    Rectangle {
        id: barBg
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.barHeight
        color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.75)
    }

    Item {
        id: atticArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: root.barHeight
        height: root.anyPopoutOpen ? root.atticHeight : 0
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
        spacing: 8

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

        BarCpu { id: cpuStat; anchors.verticalCenter: parent.verticalCenter }
        BarMemory { id: memStat; anchors.verticalCenter: parent.verticalCenter }
        BarDisk { id: diskStat; anchors.verticalCenter: parent.verticalCenter }

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
