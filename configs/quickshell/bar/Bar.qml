import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"
import "../common"

PanelWindow {
    id: root

    signal clockClicked
    signal toastDismissed(var notification)

    readonly property Theme theme: Theme {}
    readonly property int barHeight: theme.barHeight
    property bool panelOpen: false
    required property var notifications

    // the window has to cover whatever hangs off the bar - the shader has no
    // surface to draw on outside it, so a stack that outgrows the window gets
    // silently cut off. rounded up in steps so a growing stack doesn't
    // reconfigure the layer surface on every frame
    readonly property int atticFloor: 240
    readonly property int atticNeeded: toastPanel.y + toastPanel.height + 24 - barHeight

    color: "transparent"
    implicitHeight: barHeight + Math.max(atticFloor, Math.ceil(atticNeeded / 64) * 64)
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
        width: root.width
        height: root.barHeight
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
            item: toastPanel
        }
    }

    // the bar and everything hanging off it are one merged sdf surface, so a
    // popout grows out of the bar's own skin instead of being a separate card
    // floating under it
    BlobGroup {
        id: surface

        anchors.fill: parent
        color: theme.base
        borderColor: theme.muted
        borderWidth: theme.borderWidth

        shapes: [barSlab, cpuStat.popoutItem, memStat.popoutItem, diskStat.popoutItem, toastPanel]

        // overhangs every edge but the bottom one, so the only corners the field
        // can round are the ones popouts actually hang off
        BlobRect {
            id: barSlab

            readonly property int overhang: 64

            blobStatic: true
            x: -overhang
            y: -overhang
            width: root.width + overhang * 2
            height: root.barHeight + overhang
        }
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
        height: root.barHeight
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
                height: root.barHeight - 10
                radius: theme.radiusSmall
                bottomLeftRadius: 0
                bottomRightRadius: 0
                color: theme.overlay
                opacity: root.panelOpen ? 1 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: theme.transitionDuration
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

    // one panel for the whole stack rather than a blob per card: per-card blobs
    // pinch the shared left edge into a crevice at every divider. the cards are
    // plain content sitting on this surface
    BlobRect {
        id: toastPanel

        // reaches past the screen edge so the outline and its antialiasing land
        // off-screen, leaving the surface itself flush against the edge
        readonly property int overhang: 12

        visible: toastColumn.height > 0
        x: root.width - theme.toastWidth
        y: root.barHeight - theme.blobOverlap
        width: theme.toastWidth + overhang
        height: theme.blobOverlap + toastColumn.height
        radius: theme.radius

        Column {
            id: toastColumn

            y: theme.blobOverlap
            width: theme.toastWidth

            move: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: root.theme.spatialDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.theme.easingSpatial
                }
            }

            Repeater {
                // `notification` is filled from the model role of the same name
                model: root.notifications

                delegate: BarToast {
                    onDismissed: root.toastDismissed(notification)
                }
            }
        }
    }
}
