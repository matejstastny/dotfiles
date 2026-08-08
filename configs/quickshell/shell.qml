import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import "./bar"
import "./panel"
import "./wallpaper"
import "./osd"
import "./launcher"
import "./powermenu"
import "./wifi"
import "./bluetooth"
import "./calc"
import "./pickers"

ShellRoot {
    id: root

    property bool panelOpen: false
    property bool wallpaperOpen: false
    property bool dndEnabled: false
    property bool caffeinateEnabled: false

    property bool launcherOpen: false
    property bool powermenuOpen: false
    property bool wifimenuOpen: false
    property bool bluetoothmenuOpen: false
    property bool calcOpen: false
    property bool clipOpen: false
    property bool todoOpen: false
    property string todoProfile: "personal"
    property bool notesOpen: false
    property bool captureOpen: false
    property bool screenrecordOpen: false
    property bool codeOpen: false
    property bool emojiOpen: false

    NotificationServer {
        id: notifServer
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true
            if (!root.dndEnabled) {
                toastLayer.push(notification)
            }
        }
    }

    IpcHandler {
        target: "panel"
        function toggle(): void { root.panelOpen = !root.panelOpen }
        function open(): void { root.panelOpen = true }
        function hide(): void { root.panelOpen = false }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { root.wallpaperOpen = !root.wallpaperOpen }
        function open(): void { root.wallpaperOpen = true }
        function hide(): void { root.wallpaperOpen = false }
    }

    IpcHandler {
        target: "hypr"
        function refresh(): void {
            Hyprland.refreshWorkspaces()
            Hyprland.refreshMonitors()
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.launcherOpen = !root.launcherOpen }
        function open(): void { root.launcherOpen = true }
        function hide(): void { root.launcherOpen = false }
    }

    IpcHandler {
        target: "powermenu"
        function toggle(): void { root.powermenuOpen = !root.powermenuOpen }
        function open(): void { root.powermenuOpen = true }
        function hide(): void { root.powermenuOpen = false }
    }

    IpcHandler {
        target: "wifimenu"
        function toggle(): void { root.wifimenuOpen = !root.wifimenuOpen }
        function open(): void { root.wifimenuOpen = true }
        function hide(): void { root.wifimenuOpen = false }
    }

    IpcHandler {
        target: "bluetoothmenu"
        function toggle(): void { root.bluetoothmenuOpen = !root.bluetoothmenuOpen }
        function open(): void { root.bluetoothmenuOpen = true }
        function hide(): void { root.bluetoothmenuOpen = false }
    }

    IpcHandler {
        target: "calc"
        function toggle(): void { root.calcOpen = !root.calcOpen }
        function open(): void { root.calcOpen = true }
        function hide(): void { root.calcOpen = false }
    }

    IpcHandler {
        target: "clip"
        function toggle(): void { root.clipOpen = !root.clipOpen }
        function open(): void { root.clipOpen = true }
        function hide(): void { root.clipOpen = false }
    }

    IpcHandler {
        target: "todo"
        function toggle(profile: string): void {
            root.todoProfile = profile
            root.todoOpen = !root.todoOpen
        }
        function open(profile: string): void {
            root.todoProfile = profile
            root.todoOpen = true
        }
        function hide(): void { root.todoOpen = false }
    }

    IpcHandler {
        target: "notes"
        function toggle(): void { root.notesOpen = !root.notesOpen }
        function open(): void { root.notesOpen = true }
        function hide(): void { root.notesOpen = false }
    }

    IpcHandler {
        target: "capture"
        function toggle(): void { root.captureOpen = !root.captureOpen }
        function open(): void { root.captureOpen = true }
        function hide(): void { root.captureOpen = false }
    }

    IpcHandler {
        target: "screenrecord"
        function toggle(): void { root.screenrecordOpen = !root.screenrecordOpen }
        function open(): void { root.screenrecordOpen = true }
        function hide(): void { root.screenrecordOpen = false }
    }

    IpcHandler {
        target: "code"
        function toggle(): void { root.codeOpen = !root.codeOpen }
        function open(): void { root.codeOpen = true }
        function hide(): void { root.codeOpen = false }
    }

    IpcHandler {
        target: "emoji"
        function toggle(): void { root.emojiOpen = !root.emojiOpen }
        function open(): void { root.emojiOpen = true }
        function hide(): void { root.emojiOpen = false }
    }

    PanelWindow {
        id: inhibitHost
        visible: true
        implicitWidth: 1
        implicitHeight: 1
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "quickshell:caffeinate"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        focusable: false
        anchors {
            top: true
            left: true
        }
    }

    IdleInhibitor {
        window: inhibitHost
        enabled: root.caffeinateEnabled
    }

    Panel {
        id: panel
        open: root.panelOpen
        dndEnabled: root.dndEnabled
        caffeinateEnabled: root.caffeinateEnabled
        notifications: notifServer.trackedNotifications

        onToggleDnd: root.dndEnabled = !root.dndEnabled
        onToggleCaffeinate: root.caffeinateEnabled = !root.caffeinateEnabled
        onDismissNotification: notification => notification.dismiss()
        onCloseRequested: root.panelOpen = false
        onClearAll: {
            for (const notification of notifServer.trackedNotifications.values.slice()) {
                notification.dismiss()
            }
        }
    }

    Wallpaper {
        id: wallpanel
        open: root.wallpaperOpen
        onCloseRequested: root.wallpaperOpen = false
    }

    ToastLayer {
        id: toastLayer
        panelOpen: root.panelOpen
    }

    Osd {
        id: osd
    }

    Launcher {
        id: launcher
        open: root.launcherOpen
        onCloseRequested: root.launcherOpen = false
    }

    PowerMenu {
        id: powermenu
        open: root.powermenuOpen
        onCloseRequested: root.powermenuOpen = false
    }

    WifiMenu {
        id: wifimenu
        open: root.wifimenuOpen
        onCloseRequested: root.wifimenuOpen = false
    }

    BluetoothMenu {
        id: bluetoothmenu
        open: root.bluetoothmenuOpen
        onCloseRequested: root.bluetoothmenuOpen = false
    }

    Calc {
        id: calc
        open: root.calcOpen
        onCloseRequested: root.calcOpen = false
    }

    ClipPicker {
        id: clipPicker
        open: root.clipOpen
        onCloseRequested: root.clipOpen = false
    }

    TodoPicker {
        id: todoPicker
        open: root.todoOpen
        profile: root.todoProfile
        onCloseRequested: root.todoOpen = false
    }

    NotesPicker {
        id: notesPicker
        open: root.notesOpen
        onCloseRequested: root.notesOpen = false
    }

    CapturePicker {
        id: capturePicker
        open: root.captureOpen
        onCloseRequested: root.captureOpen = false
    }

    ScreenrecordPicker {
        id: screenrecordPicker
        open: root.screenrecordOpen
        onCloseRequested: root.screenrecordOpen = false
    }

    CodePicker {
        id: codePicker
        open: root.codeOpen
        onCloseRequested: root.codeOpen = false
    }

    EmojiPicker {
        id: emojiPicker
        open: root.emojiOpen
        onCloseRequested: root.emojiOpen = false
    }

    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
            panelOpen: root.panelOpen
            onClockClicked: root.panelOpen = !root.panelOpen
        }
    }
}
