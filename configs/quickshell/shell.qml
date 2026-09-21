import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import "./surface"
import "./wallpaper"
import "./osd"
import "./launcher"
import "./wifi"
import "./bluetooth"
import "./cursor"
import "./calc"
import "./pickers"
import "./cava"

ShellRoot {
    id: root

    readonly property Theme theme: Theme {}

    property bool panelOpen: false
    property bool wallpaperOpen: false
    property bool dndEnabled: false
    property bool caffeinateEnabled: false
    property bool kbdBacklightEnabled: true
    property bool typingSoundEnabled: false

    property bool launcherOpen: false
    property bool powermenuOpen: false
    property bool wifimenuOpen: false
    property bool bluetoothmenuOpen: false
    property bool cursorMenuOpen: false
    property bool calcOpen: false
    property bool clipOpen: false
    property bool todoOpen: false
    property string todoProfile: "personal"
    property bool notesOpen: false
    property bool captureOpen: false
    property bool screenrecordOpen: false
    property bool codeOpen: false
    property bool emojiOpen: false
    property bool keyboardOpen: false
    property bool cavaOpen: false

    // drawers live in every screen's Surface, but only one may open at a time:
    // two of them would each take a hyprland focus grab, and the second grab
    // cancels the first, whose clear then closes the drawer again
    property string drawerScreen: ""

    function aimDrawers(): void {
        root.drawerScreen = Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? "";
    }

    // the drawers live inside Surface rather than in PopupWindows of their own,
    // so they opt into the one-popout-at-a-time rule here instead of inheriting it
    onPanelOpenChanged: {
        if (root.panelOpen)
            PopoutState.current = "panel";
        else if (PopoutState.current === "panel")
            PopoutState.current = "";
    }

    onPowermenuOpenChanged: {
        if (root.powermenuOpen)
            PopoutState.current = "powermenu";
        else if (PopoutState.current === "powermenu")
            PopoutState.current = "";
    }

    Connections {
        target: PopoutState
        function onCurrentChanged() {
            if (PopoutState.current !== "panel")
                root.panelOpen = false;
            if (PopoutState.current !== "powermenu")
                root.powermenuOpen = false;
        }
    }

    // rendered inside each screen's Surface so the notification shape can
    // blend into the bar's own surface - a separate window could never
    // visually connect to it. newest first, so a new one buds off the bar
    // and shoves the rest down.
    //
    // a ListModel rather than a plain array: the repeater rebuilds every
    // delegate when an array is reassigned, which would replay the grow-in and
    // restart the timeout on the toasts that are merely shifting up
    ListModel {
        id: toastQueue
    }

    function pushToast(notification: var): void {
        toastQueue.insert(0, {
            notification
        });
        while (toastQueue.count > root.theme.maxToasts)
            toastQueue.remove(toastQueue.count - 1);
    }

    function dropToast(notification: var): void {
        for (let i = 0; i < toastQueue.count; i++) {
            if (toastQueue.get(i).notification === notification) {
                toastQueue.remove(i);
                return;
            }
        }
    }

    NotificationServer {
        id: notifServer
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;
            if (!root.dndEnabled)
                root.pushToast(notification);
        }
    }

    IpcHandler {
        target: "panel"
        function toggle(): void {
            root.aimDrawers();
            root.panelOpen = !root.panelOpen;
        }
        function open(): void {
            root.aimDrawers();
            root.panelOpen = true;
        }
        function hide(): void {
            root.panelOpen = false;
        }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void {
            root.wallpaperOpen = !root.wallpaperOpen;
        }
        function open(): void {
            root.wallpaperOpen = true;
        }
        function hide(): void {
            root.wallpaperOpen = false;
        }
    }

    IpcHandler {
        target: "cava"
        function toggle(): void {
            root.cavaOpen = !root.cavaOpen;
        }
        function open(): void {
            root.cavaOpen = true;
        }
        function hide(): void {
            root.cavaOpen = false;
        }
    }

    IpcHandler {
        target: "hypr"
        function refresh(): void {
            Hyprland.refreshWorkspaces();
            Hyprland.refreshMonitors();
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.launcherOpen = !root.launcherOpen;
        }
        function open(): void {
            root.launcherOpen = true;
        }
        function hide(): void {
            root.launcherOpen = false;
        }
    }

    IpcHandler {
        target: "powermenu"
        function toggle(): void {
            root.aimDrawers();
            root.powermenuOpen = !root.powermenuOpen;
        }
        function open(): void {
            root.aimDrawers();
            root.powermenuOpen = true;
        }
        function hide(): void {
            root.powermenuOpen = false;
        }
    }

    IpcHandler {
        target: "wifimenu"
        function toggle(): void {
            root.wifimenuOpen = !root.wifimenuOpen;
        }
        function open(): void {
            root.wifimenuOpen = true;
        }
        function hide(): void {
            root.wifimenuOpen = false;
        }
    }

    IpcHandler {
        target: "bluetoothmenu"
        function toggle(): void {
            root.bluetoothmenuOpen = !root.bluetoothmenuOpen;
        }
        function open(): void {
            root.bluetoothmenuOpen = true;
        }
        function hide(): void {
            root.bluetoothmenuOpen = false;
        }
    }

    IpcHandler {
        target: "cursormenu"
        function toggle(): void {
            root.cursorMenuOpen = !root.cursorMenuOpen;
        }
        function open(): void {
            root.cursorMenuOpen = true;
        }
        function hide(): void {
            root.cursorMenuOpen = false;
        }
    }

    IpcHandler {
        target: "calc"
        function toggle(): void {
            root.calcOpen = !root.calcOpen;
        }
        function open(): void {
            root.calcOpen = true;
        }
        function hide(): void {
            root.calcOpen = false;
        }
    }

    IpcHandler {
        target: "clip"
        function toggle(): void {
            root.clipOpen = !root.clipOpen;
        }
        function open(): void {
            root.clipOpen = true;
        }
        function hide(): void {
            root.clipOpen = false;
        }
    }

    IpcHandler {
        target: "todo"
        function toggle(profile: string): void {
            root.todoProfile = profile;
            root.todoOpen = !root.todoOpen;
        }
        function open(profile: string): void {
            root.todoProfile = profile;
            root.todoOpen = true;
        }
        function hide(): void {
            root.todoOpen = false;
        }
    }

    IpcHandler {
        target: "notes"
        function toggle(): void {
            root.notesOpen = !root.notesOpen;
        }
        function open(): void {
            root.notesOpen = true;
        }
        function hide(): void {
            root.notesOpen = false;
        }
    }

    IpcHandler {
        target: "capture"
        function toggle(): void {
            root.captureOpen = !root.captureOpen;
        }
        function open(): void {
            root.captureOpen = true;
        }
        function hide(): void {
            root.captureOpen = false;
        }
    }

    IpcHandler {
        target: "screenrecord"
        function toggle(): void {
            root.screenrecordOpen = !root.screenrecordOpen;
        }
        function open(): void {
            root.screenrecordOpen = true;
        }
        function hide(): void {
            root.screenrecordOpen = false;
        }
    }

    IpcHandler {
        target: "code"
        function toggle(): void {
            root.codeOpen = !root.codeOpen;
        }
        function open(): void {
            root.codeOpen = true;
        }
        function hide(): void {
            root.codeOpen = false;
        }
    }

    IpcHandler {
        target: "emoji"
        function toggle(): void {
            root.emojiOpen = !root.emojiOpen;
        }
        function open(): void {
            root.emojiOpen = true;
        }
        function hide(): void {
            root.emojiOpen = false;
        }
    }

    IpcHandler {
        target: "keyboard"
        function toggle(): void {
            root.keyboardOpen = !root.keyboardOpen;
        }
        function open(): void {
            root.keyboardOpen = true;
        }
        function hide(): void {
            root.keyboardOpen = false;
        }
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

    function setKbdBacklight(enabled) {
        kbdBacklightProc.command = ["brightnessctl", "-d", "kbd_backlight", "set", enabled ? "100%" : "0%"];
        kbdBacklightProc.running = true;
    }

    Process {
        id: kbdBacklightProc
    }

    function setTypingSound(enabled) {
        typingSoundProc.command = ["systemctl", "--user", enabled ? "enable" : "disable", "--now", "animalese-type"];
        typingSoundProc.running = true;
    }

    Process {
        id: typingSoundProc
    }

    Process {
        id: typingSoundStatusProc
        command: ["systemctl", "--user", "is-enabled", "animalese-type"]
        stdout: StdioCollector {
            onStreamFinished: root.typingSoundEnabled = text.trim() === "enabled"
        }
    }

    Component.onCompleted: {
        root.setKbdBacklight(root.kbdBacklightEnabled);
        typingSoundStatusProc.running = true;
    }

    Wallpaper {
        id: wallpanel
        open: root.wallpaperOpen
        onCloseRequested: root.wallpaperOpen = false
    }

    Cava {
        id: cava
        open: root.cavaOpen
    }

    Osd {
        id: osd
    }

    Launcher {
        id: launcher
        open: root.launcherOpen
        onCloseRequested: root.launcherOpen = false
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

    CursorMenu {
        id: cursormenu
        open: root.cursorMenuOpen
        onCloseRequested: root.cursorMenuOpen = false
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

    KeyboardPicker {
        id: keyboardPicker
        open: root.keyboardOpen
        onCloseRequested: root.keyboardOpen = false
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: scope

            required property var modelData

            Exclusions {
                screen: scope.modelData
            }

            Surface {
                screen: scope.modelData
                toasts: toastQueue
                notifications: notifServer.trackedNotifications

                panelOpen: root.panelOpen && scope.modelData.name === root.drawerScreen
                powerMenuOpen: root.powermenuOpen && scope.modelData.name === root.drawerScreen
                dndEnabled: root.dndEnabled
                caffeinateEnabled: root.caffeinateEnabled
                kbdBacklightEnabled: root.kbdBacklightEnabled
                typingSoundEnabled: root.typingSoundEnabled
                cavaEnabled: root.cavaOpen

                onClockClicked: {
                    root.aimDrawers();
                    root.panelOpen = !root.panelOpen;
                }
                onToastDismissed: notification => root.dropToast(notification)
                onPanelCloseRequested: root.panelOpen = false
                onPowerMenuCloseRequested: root.powermenuOpen = false
                onToggleDnd: root.dndEnabled = !root.dndEnabled
                onToggleCaffeinate: root.caffeinateEnabled = !root.caffeinateEnabled
                onToggleKbdBacklight: {
                    root.kbdBacklightEnabled = !root.kbdBacklightEnabled;
                    root.setKbdBacklight(root.kbdBacklightEnabled);
                }
                onToggleTypingSound: {
                    root.typingSoundEnabled = !root.typingSoundEnabled;
                    root.setTypingSound(root.typingSoundEnabled);
                }
                onToggleCava: root.cavaOpen = !root.cavaOpen
                onDismissNotification: notification => notification.dismiss()
                onClearAll: {
                    for (const notification of notifServer.trackedNotifications.values.slice())
                        notification.dismiss();
                }
            }
        }
    }
}
