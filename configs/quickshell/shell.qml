import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import "./bar"
import "./panel"

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
        target: "hypr"
        function refresh(): void {
            Hyprland.refreshWorkspaces()
            Hyprland.refreshMonitors()
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
