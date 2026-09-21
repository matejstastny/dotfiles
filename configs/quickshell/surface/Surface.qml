import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../"
import "../common"
import "../bar"
import "../panel"
import "../powermenu"

// one window per screen holding every fixed surface: the outline, the bar that
// forms its top side, the toast stack and the drawers. they all have to share a
// window because they all have to share one sdf field - a blob in a window of
// its own could never fuse with anything outside it
PanelWindow {
    id: root

    signal clockClicked
    signal toastDismissed(var notification)
    signal panelCloseRequested
    signal powerMenuCloseRequested
    signal toggleDnd
    signal toggleCaffeinate
    signal toggleKbdBacklight
    signal toggleTypingSound
    signal toggleCava
    signal clearAll
    signal dismissNotification(var notification)

    required property var toasts
    required property var notifications
    property bool panelOpen: false
    property bool powerMenuOpen: false
    property bool dndEnabled: false
    property bool caffeinateEnabled: false
    property bool kbdBacklightEnabled: true
    property bool typingSoundEnabled: false
    property bool cavaEnabled: false

    readonly property bool anyDrawerOpen: panelOpen || powerMenuOpen

    readonly property Theme theme: Theme {}
    readonly property int barHeight: theme.barHeight
    readonly property int frameThickness: theme.frameThickness

    // the usable area inside the outline, in window coordinates. drawers park
    // just outside it and slide in to sit flush against its edges
    readonly property rect contentArea: Qt.rect(frameThickness, barHeight, width - frameThickness * 2, height - barHeight - frameThickness)

    color: "transparent"

    // the outline covers all four edges, and layershell only honours an
    // exclusive zone on a window anchored to one - Exclusions reserves the
    // space instead, one throwaway window per side
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:surface"
    // OnDemand, not Exclusive: this surface is already mapped when a drawer
    // opens, and hyprland clears a focus grab taken over a surface that
    // switches to exclusive under it - the grab is what hands us the keys
    WlrLayershell.keyboardFocus: root.anyDrawerOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    focusable: false

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // the window spans the screen, so without a mask the outline's dead centre
    // would swallow every click on the desktop
    mask: Region {
        width: root.width
        height: root.barHeight

        Region {
            y: root.height - root.frameThickness
            width: root.width
            height: root.frameThickness
        }
        Region {
            y: root.barHeight
            width: root.frameThickness
            height: root.height - root.barHeight - root.frameThickness
        }
        Region {
            x: root.width - root.frameThickness
            y: root.barHeight
            width: root.frameThickness
            height: root.height - root.barHeight - root.frameThickness
        }
        Region {
            item: bar.cpuStat.hovered ? bar.cpuStat.popoutItem : null
        }
        Region {
            item: bar.memStat.hovered ? bar.memStat.popoutItem : null
        }
        Region {
            item: bar.diskStat.hovered ? bar.diskStat.popoutItem : null
        }
        Region {
            item: toastPanel
        }
        Region {
            item: panelDrawer
        }
        Region {
            item: powerDrawer
        }
    }

    // only the screen the drawer actually opened on may grab: a second grab
    // cancels the first, and the first's clear would slam the drawer shut again
    HyprlandFocusGrab {
        active: root.anyDrawerOpen
        windows: [root]
        onCleared: {
            root.panelCloseRequested();
            root.powerMenuCloseRequested();
        }
    }

    BlobGroup {
        id: surface

        anchors.fill: parent
        color: theme.base
        borderColor: theme.muted
        borderWidth: theme.borderWidth

        frame: frame
        shapes: [bar.cpuStat.popoutItem, bar.memStat.popoutItem, bar.diskStat.popoutItem, toastPanel, panelDrawer, powerDrawer]

        // overhangs the screen on every side, so the outer edge, its blend and
        // the bulge of a parked drawer all land off-screen and the only thing
        // left on it is the inner wall
        BlobFrame {
            id: frame

            readonly property int overhang: 50

            anchors.fill: parent
            anchors.margins: -overhang
            borderLeft: root.frameThickness + overhang
            borderRight: root.frameThickness + overhang
            borderTop: root.barHeight + overhang
            borderBottom: root.frameThickness + overhang
        }
    }

    Bar {
        id: bar

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.barHeight

        screen: root.screen
        panelOpen: root.panelOpen
        onClockClicked: root.clockClicked()
    }

    // one panel for the whole stack rather than a blob per card: per-card blobs
    // pinch the shared left edge into a crevice at every divider. the cards are
    // plain content sitting on this surface
    BlobRect {
        id: toastPanel

        visible: toastColumn.height > 0
        x: root.contentArea.x + root.contentArea.width - width
        y: root.contentArea.y
        width: theme.toastWidth
        height: toastColumn.height
        radius: theme.radius

        Column {
            id: toastColumn

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
                model: root.toasts

                delegate: BarToast {
                    onDismissed: root.toastDismissed(notification)
                }
            }
        }
    }

    BlobDrawer {
        id: panelDrawer

        edge: "top"
        open: root.panelOpen
        area: root.contentArea
        width: 820
        height: 560

        Panel {
            anchors.fill: parent
            anchors.margins: 20

            open: root.panelOpen
            notifications: root.notifications
            dndEnabled: root.dndEnabled
            caffeinateEnabled: root.caffeinateEnabled
            kbdBacklightEnabled: root.kbdBacklightEnabled
            typingSoundEnabled: root.typingSoundEnabled
            cavaEnabled: root.cavaEnabled

            onCloseRequested: root.panelCloseRequested()
            onToggleDnd: root.toggleDnd()
            onToggleCaffeinate: root.toggleCaffeinate()
            onToggleKbdBacklight: root.toggleKbdBacklight()
            onToggleTypingSound: root.toggleTypingSound()
            onToggleCava: root.toggleCava()
            onClearAll: root.clearAll()
            onDismissNotification: notification => root.dismissNotification(notification)
        }
    }

    BlobDrawer {
        id: powerDrawer

        edge: "right"
        open: root.powerMenuOpen
        area: root.contentArea
        width: powerContent.implicitWidth
        height: powerContent.implicitHeight

        PowerMenu {
            id: powerContent

            anchors.fill: parent

            open: root.powerMenuOpen
            onCloseRequested: root.powerMenuCloseRequested()
        }
    }
}
