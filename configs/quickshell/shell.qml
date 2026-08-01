import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications

ShellRoot {
    id: root

    property bool panelOpen: false
    property bool dndEnabled: false
    property bool caffeinateEnabled: false

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
                Quickshell.execDetached(["paplay", "/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"])
            }
        }
    }

    IpcHandler {
        target: "panel"
        function toggle(): void { root.panelOpen = !root.panelOpen }
        function open(): void { root.panelOpen = true }
        function hide(): void { root.panelOpen = false }
    }

    // the panel never grabs focus (so it never steals it from real apps), so
    // "close on click outside" is implemented by watching Hyprland for a real
    // app window becoming active instead of us intercepting the click
    Connections {
        target: Hyprland
        function onActiveToplevelChanged() {
            root.panelOpen = false
        }
    }

    // 1x1 always-mapped surface purely to host the idle inhibitor
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
        onClearAll: {
            for (const notification of notifServer.trackedNotifications.values) {
                notification.dismiss()
            }
        }
    }

    ToastLayer {
        id: toastLayer
        panelOpen: root.panelOpen
    }

    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
            onClockClicked: root.panelOpen = !root.panelOpen
        }
    }
}
