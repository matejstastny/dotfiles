import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// one surface's entire outside world: the ipc target scripts call, and the
// hyprland global shortcut the keybind fires. both are named after the surface,
// so `qs ipc call clip toggle` and `quickshell:clip` can never drift apart.
//
// the shortcut matters more than it looks: a `qs ipc call` bind forks a process,
// opens the socket and exits on every keypress. a global shortcut is a wayland
// message into the already-running shell
Scope {
    id: root

    required property string name
    required property string about

    // drawers are rendered inside every screen's Surface, so the monitor they
    // should appear on has to be chosen before one opens. popups that own their
    // window follow the pointer by themselves and leave this false
    property bool aims: false

    property bool shown: false

    // surfaces that come in flavours (the todo list is either the personal or
    // the stars file) get one extra shortcut per flavour rather than an ipc
    // argument, so every ipc function in the shell keeps the same no-arg shape.
    // entries are { suffix, value }
    property var variants: []
    property string variant: ""

    signal aimRequested

    function set(value: bool): void {
        if (value && root.aims)
            root.aimRequested();
        root.shown = value;
    }

    IpcHandler {
        target: root.name

        function toggle(): void {
            root.set(!root.shown);
        }
        function open(): void {
            root.set(true);
        }
        function hide(): void {
            root.set(false);
        }
        function show(variant: string): void {
            root.variant = variant;
            root.set(true);
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: root.name
        description: root.about
        // press, not release. hyprland drops a bind entirely once the modmask
        // stops matching, so releasing ALT before the key means no release event
        // ever arrives - it only pairs press with release for its own `global`
        // handler, and `hl.dsp.global` reaches it as an opaque `__lua` bind
        onPressed: {
            if (root.variants.length > 0)
                root.variant = root.variants[0].value;
            root.set(!root.shown);
        }
    }

    Instantiator {
        model: root.variants

        delegate: GlobalShortcut {
            required property var modelData

            appid: "quickshell"
            name: `${root.name}-${modelData.suffix}`
            description: `${root.about} (${modelData.suffix})`
            onPressed: {
                root.variant = modelData.value;
                root.set(!root.shown);
            }
        }
    }
}
