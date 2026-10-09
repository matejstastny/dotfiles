import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../"
import "../common"
import "../bar"
import "../panel"
import "../powermenu"
import "../wallpaper"
import "../osd"

// one window per screen holding every fixed surface: the outline, the bar that
// forms its top side, the toast stack and the drawers. they all have to share a
// window because they all have to share one sdf field - a blob in a window of
// its own could never fuse with anything outside it
PanelWindow {
    id: root

    signal panelRequested
    signal toastDismissed(var notification)
    signal panelCloseRequested
    signal powerMenuCloseRequested
    signal wallpaperCloseRequested
    // whatever is open, close it - what a click outside means
    signal dismissRequested
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
    property bool wallpaperOpen: false

    // the command surface currently asking to be shown on this screen, or null.
    // the picker objects themselves live in shell.qml so their models and
    // processes exist once; only the body they hand over is built here
    property var command: null

    // latched, so the slide-out still has something to draw. `command` goes
    // null the instant the picker closes, which is a whole animation early
    property var shownCommand: null
    onCommandChanged: if (root.command)
        root.shownCommand = root.command

    readonly property bool commandOpen: root.command !== null
    property bool osdOpen: false
    property string osdKind: "volume"
    property int osdPct: 0
    property bool osdMuted: false
    property bool dndEnabled: false
    property bool caffeinateEnabled: false
    property bool kbdBacklightEnabled: true
    property bool typingSoundEnabled: false
    property bool cavaEnabled: false

    readonly property bool anyDrawerOpen: panelOpen || powerMenuOpen || wallpaperOpen || commandOpen

    readonly property int barHeight: Theme.barHeight
    readonly property int frameThickness: Theme.frameThickness

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
            item: toastPanel
        }
        Region {
            item: panelDrawer
        }
        Region {
            item: powerDrawer
        }
        Region {
            item: wallpaperDrawer
        }
        Region {
            item: osdDrawer
        }
        Region {
            item: commandDrawer
        }
    }

    // only the screen the drawer actually opened on may grab: a second grab
    // cancels the first, and the first's clear would slam the drawer shut again
    // same late arming as the focus grab above: the keybind that opened the drawer is
    // still held when the grab would be taken, and its release would clear it
    property bool grabArmed: false

    Timer {
        id: grabArmTimer
        interval: Theme.grabArmDelay
        onTriggered: root.grabArmed = true
    }

    onAnyDrawerOpenChanged: {
        if (root.anyDrawerOpen)
            grabArmTimer.restart();
        else {
            grabArmTimer.stop();
            root.grabArmed = false;
        }
    }

    HyprlandFocusGrab {
        active: root.anyDrawerOpen && root.grabArmed
        windows: [root]
        onCleared: root.dismissRequested()
    }

    BlobGroup {
        id: surface

        anchors.fill: parent
        color: Theme.base
        borderColor: Theme.muted
        borderWidth: Theme.borderWidth

        frame: frame
        shapes: [bar.cpuStat.popoutItem, bar.memStat.popoutItem, bar.diskStat.popoutItem, bar.batteryStat.popoutItem, bar.volumeStat.popoutItem, bar.recordingStat.popoutItem, bar.tailscaleStat.popoutItem, bar.dockerStat.popoutItem, bar.quickshareStat.popoutItem, toastPanel, panelDrawer, powerDrawer, wallpaperDrawer, osdDrawer, commandDrawer]

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
        onPanelRequested: root.panelRequested()
    }

    // one panel for the whole stack rather than a blob per card: per-card blobs
    // pinch the shared left edge into a crevice at every divider. the cards are
    // plain content sitting on this surface
    BlobRect {
        id: toastPanel

        visible: toastColumn.height > 0
        x: root.contentArea.x + root.contentArea.width - width
        y: root.contentArea.y
        width: Theme.toastWidth
        height: toastColumn.height
        radius: Theme.radius

        Column {
            id: toastColumn

            width: Theme.toastWidth

            move: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: Theme.spatialDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.easingSpatial
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
        // the panel is as big as it has things to say: a rail on its own most
        // of the time, a second column once something has notified. a fixed
        // 820x560 looked identical whether it was empty or full
        width: Math.min(root.contentArea.width - Theme.paddingLarge * 2, panelContent.implicitWidth + Theme.paddingLarge * 2)
        height: panelContent.implicitHeight + Theme.paddingLarge * 2
        animationDuration: 140
        animationEasing: Easing.OutCubic
        deformScale: 0

        Behavior on width {
            NumberAnimation {
                duration: Theme.spatialDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.easingDrawer
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: Theme.spatialDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.easingDrawer
            }
        }

        Panel {
            id: panelContent

            anchors.fill: parent
            anchors.margins: Theme.paddingLarge

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

    BlobDrawer {
        id: wallpaperDrawer

        edge: "bottom"
        open: root.wallpaperOpen
        area: root.contentArea
        width: Math.min(root.contentArea.width - 80, 1120)
        height: 250

        Wallpaper {
            anchors.fill: parent
            anchors.margins: Theme.paddingLarge
            open: root.wallpaperOpen
            onCloseRequested: root.wallpaperCloseRequested()
        }
    }

    BlobDrawer {
        id: osdDrawer

        edge: "bottom"
        open: root.osdOpen
        area: root.contentArea
        width: osdContent.implicitWidth + 36
        height: osdContent.implicitHeight + 28

        Osd {
            id: osdContent
            anchors.centerIn: parent
            open: root.osdOpen
            kind: root.osdKind
            pct: root.osdPct
            muted: root.osdMuted
        }
    }

    // the launcher and every picker. one drawer, whichever keybind you hit, so
    // they all come out of the same edge at the same place and fuse into the
    // bar the way the panel does
    BlobDrawer {
        id: commandDrawer

        edge: "top"
        open: root.commandOpen
        area: root.contentArea
        // a prompt that resizes on every keystroke has no business springing
        deformScale: 0
        animationDuration: Theme.drawerDuration

        // buried in the bar by the same amount a bar popout is, so the join has
        // material either side of it no matter where the pixel grid lands
        sink: Theme.blobOverlap

        width: (root.shownCommand ? root.shownCommand.surfaceWidth : Theme.commandWidth) + Theme.padding * 2
        height: commandLoader.item ? commandLoader.implicitHeight + Theme.padding * 2 + commandDrawer.sink : 0

        Behavior on width {
            NumberAnimation {
                duration: Theme.snapDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.easingEffects
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: Theme.snapDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.easingEffects
            }
        }

        Loader {
            id: commandLoader

            anchors.fill: parent
            // the sunk edge is behind the bar, so the content starts below it
            // and the card you can actually see is unchanged
            anchors.topMargin: Theme.padding + commandDrawer.sink
            anchors.leftMargin: Theme.padding
            anchors.rightMargin: Theme.padding
            anchors.bottomMargin: Theme.padding
            focus: true

            // kept alive through the slide-out, then torn down. nothing of a
            // picker's state lives in here, so there is nothing to preserve
            active: root.commandOpen || commandDrawer.progress > 0.001
            sourceComponent: root.shownCommand ? root.shownCommand.body : null

            // deferred a tick: at onLoaded the body exists but is not yet
            // parented into this window, and focus taken before then is dropped
            onLoaded: Qt.callLater(() => {
                if (root.shownCommand)
                    root.shownCommand.focusView();
            })
        }
    }
}
