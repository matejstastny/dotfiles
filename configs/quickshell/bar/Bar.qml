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

    readonly property alias cpuStat: cpuStat
    readonly property alias memStat: memStat
    readonly property alias diskStat: diskStat
    readonly property alias batteryStat: batteryStat
    readonly property alias volumeStat: volumeStat
    readonly property alias recordingStat: recordingStat
    readonly property alias tailscaleStat: tailscaleStat
    readonly property alias dockerStat: dockerStat
    readonly property alias quickshareStat: quickshareStat

    implicitHeight: Theme.barHeight

    readonly property bool isLaptopScreen: Monitors.isLaptop(screen)
    readonly property string dotfilesScripts: Quickshell.env("HOME") + "/dotfiles/scripts"
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
            id: recordingStat
            anchors.verticalCenter: parent.verticalCenter
            script: root.dotfilesScripts + "/bar-recording.sh"
            interval: 1000
            onClickCommand: root.dotfilesScripts + "/record.sh"
        }

        BarScriptModule {
            id: tailscaleStat
            anchors.verticalCenter: parent.verticalCenter
            script: root.dotfilesScripts + "/bar-tailscale.sh"
            interval: 10000
            onClickCommand: "tailscale up"
        }

        BarScriptModule {
            id: dockerStat
            anchors.verticalCenter: parent.verticalCenter
            script: root.dotfilesScripts + "/bar-docker.sh"
            interval: 5000
            onClickCommand: "kitty -e sh -c 'docker ps; read'"
        }

        BarScriptModule {
            id: quickshareStat
            anchors.verticalCenter: parent.verticalCenter
            script: root.dotfilesScripts + "/bar-quickshare.sh"
            interval: 5000
            onClickCommand: root.dotfilesScripts + "/quickshare-recopy.sh"
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
            id: volumeStat
            anchors.verticalCenter: parent.verticalCenter
        }
        BarBattery {
            id: batteryStat
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
            color: Theme.dim
            font.pixelSize: Theme.barFontSize - 1
            font.family: Theme.fontMono
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
