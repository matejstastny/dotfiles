import QtQuick
import Quickshell.Services.Mpris
import Quickshell
import "../"

// content only - the bar has no surface of its own any more. it is the top side
// of the frame in Surface's blob field, so the slab you see behind these modules
// is drawn by the same shader as the screen outline and every drawer
Item {
    id: root

    signal panelRequested

    required property var screen
    property bool panelOpen: false

    readonly property Theme theme: Theme {}

    readonly property alias cpuStat: cpuStat
    readonly property alias memStat: memStat
    readonly property alias diskStat: diskStat

    implicitHeight: theme.barHeight

    readonly property bool isLaptopScreen: screen && screen.name === "eDP-1"
    readonly property var activePlayer: {
        const players = Mpris.players.values;
        for (let i = 0; i < players.length; i++)
            if (players[i].isPlaying)
                return players[i];
        return players.length > 0 ? players[0] : null;
    }

    Row {
        anchors.left: parent.left
        anchors.top: parent.top
        height: parent.height
        anchors.leftMargin: 10
        spacing: 8

        BarLogo {
            anchors.verticalCenter: parent.verticalCenter
        }

        BarSep {
            anchors.verticalCenter: parent.verticalCenter
        }

        BarWorkspaces {
            anchors.verticalCenter: parent.verticalCenter
            screen: root.screen
        }

        BarSep {
            anchors.verticalCenter: parent.verticalCenter
        }

        BarActiveWindow {
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        height: parent.height
        anchors.rightMargin: 10
        spacing: 8

        BarTray {
            id: tray
            anchors.verticalCenter: parent.verticalCenter
        }

        BarSep {
            anchors.verticalCenter: parent.verticalCenter
            visible: tray.visible
        }

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

        BarSep {
            anchors.verticalCenter: parent.verticalCenter
        }

        BarCpu {
            id: cpuStat
            anchors.verticalCenter: parent.verticalCenter
        }
        BarMemory {
            id: memStat
            anchors.verticalCenter: parent.verticalCenter
        }
        BarDisk {
            id: diskStat
            anchors.verticalCenter: parent.verticalCenter
        }

        BarSep {
            anchors.verticalCenter: parent.verticalCenter
        }

        BarVolume {
            anchors.verticalCenter: parent.verticalCenter
        }
        BarBattery {
            anchors.verticalCenter: parent.verticalCenter
        }

        BarSep {
            anchors.verticalCenter: parent.verticalCenter
        }

        BarClock {
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(480, parent.width * 0.36)
        height: parent.height
        visible: !root.isLaptopScreen && root.activePlayer && root.activePlayer.trackTitle

        Text {
            anchors.centerIn: parent
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: !root.activePlayer ? "" : (root.activePlayer.trackArtist
                ? root.activePlayer.trackTitle + "  ·  " + root.activePlayer.trackArtist
                : root.activePlayer.trackTitle)
            color: theme.dim
            font.pixelSize: theme.barFontSize - 1
            font.family: theme.fontFamily
            font.weight: Font.Normal
        }
    }

    MouseArea {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: 180
        height: 5
        hoverEnabled: true
        onEntered: root.panelRequested()
    }
}
