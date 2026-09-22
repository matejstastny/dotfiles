import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import "./common"
import "./surface"
import "./launcher"
import "./wifi"
import "./bluetooth"
import "./cursor"
import "./pickers"
import "./cava"

ShellRoot {
    id: root

    property bool osdOpen: false
    property string osdKind: "volume"
    property int osdPct: 0
    property bool osdMuted: false
    property bool dndEnabled: false
    property bool caffeinateEnabled: false
    property bool kbdBacklightEnabled: true
    property bool typingSoundEnabled: false

    // drawers live in every screen's Surface, but only one may open at a time:
    // two of them would each take a hyprland focus grab, and the second grab
    // cancels the first, whose clear then closes the drawer again
    property string drawerScreen: ""

    function aimDrawers(): void {
        root.drawerScreen = Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? "";
    }

    function clearNotifications(): void {
        for (const notification of notifServer.trackedNotifications.values.slice())
            notification.dismiss();
    }

    // every surface the outside world can open. the ipc target, the global
    // shortcut name and the id here are all the same word
    Popout {
        id: panelPopout
        name: "panel"
        about: "Toggle the control panel"
        aims: true
        onAimRequested: root.aimDrawers()
    }
    Popout {
        id: powermenuPopout
        name: "powermenu"
        about: "Toggle the power menu"
        aims: true
        onAimRequested: root.aimDrawers()
    }
    Popout {
        id: wallpaperPopout
        name: "wallpaper"
        about: "Toggle the wallpaper picker"
        aims: true
        onAimRequested: root.aimDrawers()
    }
    Popout {
        id: launcherPopout
        name: "launcher"
        about: "Toggle the app launcher"
    }
    Popout {
        id: wifiPopout
        name: "wifimenu"
        about: "Toggle the wifi menu"
    }
    Popout {
        id: bluetoothPopout
        name: "bluetoothmenu"
        about: "Toggle the bluetooth menu"
    }
    Popout {
        id: cursorPopout
        name: "cursormenu"
        about: "Toggle the cursor theme picker"
    }
    Popout {
        id: clipPopout
        name: "clip"
        about: "Toggle clipboard history"
    }
    Popout {
        id: todoPopout
        name: "todo"
        about: "Toggle the todo list"
        variants: [
            {
                suffix: "personal",
                value: "personal"
            },
            {
                suffix: "stars",
                value: "stars"
            }
        ]
    }
    Popout {
        id: notesPopout
        name: "notes"
        about: "Toggle the notes picker"
    }
    Popout {
        id: capturePopout
        name: "capture"
        about: "Toggle quick capture"
    }
    Popout {
        id: screenrecordPopout
        name: "screenrecord"
        about: "Toggle the screen recorder"
    }
    Popout {
        id: codePopout
        name: "code"
        about: "Toggle the project picker"
    }
    Popout {
        id: emojiPopout
        name: "emoji"
        about: "Toggle the emoji picker"
    }
    Popout {
        id: keyboardPopout
        name: "keyboard"
        about: "Toggle the keyboard layout picker"
    }
    Popout {
        id: cavaPopout
        name: "cava"
        about: "Toggle the desktop visualiser"
    }

    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property bool audioSinkReady: audioSink && audioSink.audio

    PwObjectTracker {
        objects: root.audioSink ? [root.audioSink] : []
    }

    function revealOsd(): void {
        root.aimDrawers();
        root.osdOpen = true;
        osdHideTimer.restart();
    }

    function showVolumeOsd(): void {
        root.osdKind = "volume";
        root.osdPct = root.audioSinkReady ? Math.round(root.audioSink.audio.volume * 100) : 0;
        root.osdMuted = root.audioSinkReady && root.audioSink.audio.muted;
        root.revealOsd();
    }

    // the drawers live inside Surface rather than in PopupWindows of their own,
    // so they opt into the one-popout-at-a-time rule here instead of inheriting it
    Connections {
        target: panelPopout
        function onShownChanged() {
            if (panelPopout.shown)
                PopoutState.current = "panel";
            else if (PopoutState.current === "panel")
                PopoutState.current = "";
        }
    }

    Connections {
        target: powermenuPopout
        function onShownChanged() {
            if (powermenuPopout.shown)
                PopoutState.current = "powermenu";
            else if (PopoutState.current === "powermenu")
                PopoutState.current = "";
        }
    }

    Connections {
        target: PopoutState
        function onCurrentChanged() {
            if (PopoutState.current !== "panel")
                panelPopout.shown = false;
            if (PopoutState.current !== "powermenu")
                powermenuPopout.shown = false;
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
        while (toastQueue.count > Theme.maxToasts)
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

    // panel is the only surface with a verb of its own: the bind does double
    // duty, clearing notifications when the panel is up and centering the
    // focused window when it is not
    IpcHandler {
        target: "panelextra"
        function clearOrCenter(): void {
            if (panelPopout.shown)
                root.clearNotifications();
            else
                Quickshell.execDetached(["hyprctl", "dispatch", "centerwindow"]);
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "clear-or-center"
        description: "Clear notifications, or centre the focused window"
        onPressed: {
            if (panelPopout.shown)
                root.clearNotifications();
            else
                Quickshell.execDetached(["hyprctl", "dispatch", "centerwindow"]);
        }
    }

    function stepVolume(action: string): void {
        if (!root.audioSinkReady)
            return;
        if (action === "raise") {
            if (root.audioSink.audio.muted)
                root.audioSink.audio.muted = false;
            root.audioSink.audio.volume = Math.min(1, root.audioSink.audio.volume + 0.05);
        } else if (action === "lower") {
            root.audioSink.audio.volume = Math.max(0, root.audioSink.audio.volume - 0.05);
        } else if (action === "mute-toggle") {
            root.audioSink.audio.muted = !root.audioSink.audio.muted;
        }
        root.showVolumeOsd();
    }

    function stepBrightness(action: string): void {
        brightnessProc.command = ["brightnessctl", "-m", "set", action === "raise" ? "5%+" : "5%-"];
        brightnessProc.running = true;
    }

    IpcHandler {
        target: "osd"

        function volume(action: string): void {
            root.stepVolume(action);
        }

        function brightness(action: string): void {
            root.stepBrightness(action);
        }
    }

    // the media keys are held down and repeat, so they were the worst offenders
    // of the lot: a fork, a socket connect and a process teardown per 5% step.
    // driving pipewire and mpris straight from here costs none of that
    Instantiator {
        model: [
            {
                key: "volume-up",
                about: "Raise volume",
                run: () => root.stepVolume("raise")
            },
            {
                key: "volume-down",
                about: "Lower volume",
                run: () => root.stepVolume("lower")
            },
            {
                key: "volume-mute",
                about: "Toggle mute",
                run: () => root.stepVolume("mute-toggle")
            },
            {
                key: "brightness-up",
                about: "Raise brightness",
                run: () => root.stepBrightness("raise")
            },
            {
                key: "brightness-down",
                about: "Lower brightness",
                run: () => root.stepBrightness("lower")
            },
            {
                key: "media-play-pause",
                about: "Play/pause media",
                run: () => root.mediaPlayer?.togglePlaying()
            },
            {
                key: "media-next",
                about: "Next track",
                run: () => root.mediaPlayer?.next()
            },
            {
                key: "media-prev",
                about: "Previous track",
                run: () => root.mediaPlayer?.previous()
            }
        ]

        delegate: GlobalShortcut {
            required property var modelData

            appid: "quickshell"
            name: modelData.key
            description: modelData.about
            onPressed: modelData.run()
        }
    }

    // whoever is playing, else whoever is there. matches what the bar shows
    readonly property var mediaPlayer: {
        const players = Mpris.players.values;
        for (let i = 0; i < players.length; i++)
            if (players[i].isPlaying)
                return players[i];
        return players.length > 0 ? players[0] : null;
    }

    Timer {
        id: osdHideTimer
        interval: 1400
        onTriggered: root.osdOpen = false
    }

    Process {
        id: brightnessProc
        stdout: SplitParser {
            onRead: data => {
                const pct = parseInt(data.trim().split(",")[3]);
                if (isNaN(pct))
                    return;
                root.osdKind = "brightness";
                root.osdPct = pct;
                root.osdMuted = false;
                root.revealOsd();
            }
        }
    }

    IpcHandler {
        target: "hypr"
        function refresh(): void {
            Hyprland.refreshWorkspaces();
            Hyprland.refreshMonitors();
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

    Cava {
        id: cava
        open: cavaPopout.shown
    }

    Launcher {
        open: launcherPopout.shown
        onCloseRequested: launcherPopout.shown = false
    }

    WifiMenu {
        open: wifiPopout.shown
        onCloseRequested: wifiPopout.shown = false
    }

    BluetoothMenu {
        open: bluetoothPopout.shown
        onCloseRequested: bluetoothPopout.shown = false
    }

    CursorMenu {
        open: cursorPopout.shown
        onCloseRequested: cursorPopout.shown = false
    }

    ClipPicker {
        open: clipPopout.shown
        onCloseRequested: clipPopout.shown = false
    }

    TodoPicker {
        open: todoPopout.shown
        profile: todoPopout.variant || "personal"
        onCloseRequested: todoPopout.shown = false
    }

    NotesPicker {
        open: notesPopout.shown
        onCloseRequested: notesPopout.shown = false
    }

    CapturePicker {
        open: capturePopout.shown
        onCloseRequested: capturePopout.shown = false
    }

    ScreenrecordPicker {
        open: screenrecordPopout.shown
        onCloseRequested: screenrecordPopout.shown = false
    }

    CodePicker {
        open: codePopout.shown
        onCloseRequested: codePopout.shown = false
    }

    EmojiPicker {
        open: emojiPopout.shown
        onCloseRequested: emojiPopout.shown = false
    }

    KeyboardPicker {
        open: keyboardPopout.shown
        onCloseRequested: keyboardPopout.shown = false
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

                panelOpen: panelPopout.shown && scope.modelData.name === root.drawerScreen
                powerMenuOpen: powermenuPopout.shown && scope.modelData.name === root.drawerScreen
                wallpaperOpen: wallpaperPopout.shown && scope.modelData.name === root.drawerScreen
                osdOpen: root.osdOpen && scope.modelData.name === root.drawerScreen
                osdKind: root.osdKind
                osdPct: root.osdPct
                osdMuted: root.osdMuted
                dndEnabled: root.dndEnabled
                caffeinateEnabled: root.caffeinateEnabled
                kbdBacklightEnabled: root.kbdBacklightEnabled
                typingSoundEnabled: root.typingSoundEnabled
                cavaEnabled: cavaPopout.shown

                onPanelRequested: panelPopout.set(true)
                onToastDismissed: notification => root.dropToast(notification)
                onPanelCloseRequested: panelPopout.shown = false
                onPowerMenuCloseRequested: powermenuPopout.shown = false
                onWallpaperCloseRequested: wallpaperPopout.shown = false
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
                onToggleCava: cavaPopout.set(!cavaPopout.shown)
                onDismissNotification: notification => notification.dismiss()
                onClearAll: root.clearNotifications()
            }
        }
    }
}
