import QtQuick
import Quickshell
import "../"

// content only - the bar has no surface of its own any more. it is the top side
// of the frame in Surface's blob field, so the slab you see behind these modules
// is drawn by the same shader as the screen outline and every drawer
Item {
    id: root

    signal clockClicked

    required property var screen
    property bool panelOpen: false

    readonly property Theme theme: Theme {}

    readonly property alias cpuStat: cpuStat
    readonly property alias memStat: memStat
    readonly property alias diskStat: diskStat

    implicitHeight: theme.barHeight

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
            anchors.verticalCenter: parent.verticalCenter
        }

        BarSep {
            anchors.verticalCenter: parent.verticalCenter
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

        Item {
            id: clockSlot
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: clockBg.width
            implicitHeight: clock.implicitHeight

            Rectangle {
                id: clockBg
                anchors.centerIn: parent
                width: clock.implicitWidth + 16
                height: root.theme.barHeight - 10
                radius: root.theme.radiusSmall
                bottomLeftRadius: 0
                bottomRightRadius: 0
                color: root.theme.overlay
                opacity: root.panelOpen ? 1 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: root.theme.transitionDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }

            BarClock {
                id: clock
                anchors.centerIn: parent
                onClicked: root.clockClicked()
            }
        }
    }
}
