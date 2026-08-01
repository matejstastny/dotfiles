import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../"

PanelWindow {
    id: root

    readonly property Theme theme: Theme {}
    property var queue: []
    property bool panelOpen: false

    function push(notification) {
        root.queue = root.queue.concat([notification])
    }
    function popAt(index) {
        const copy = root.queue.slice()
        copy.splice(index, 1)
        root.queue = copy
    }
    function remove(notification) {
        const idx = root.queue.indexOf(notification)
        if (idx !== -1) root.popAt(idx)
    }

    visible: queue.length > 0
    color: "transparent"
    implicitWidth: 360
    implicitHeight: Math.max(1, column.implicitHeight)
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:toasts"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    focusable: false

    anchors {
        top: true
        right: true
    }
    margins {
        top: root.panelOpen ? 720 : 10
        right: 10
    }
    Behavior on margins.top { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    Column {
        id: column
        width: parent.width
        spacing: 10

        Repeater {
            model: root.queue
            delegate: NotificationCard {
                required property var modelData
                required property int index

                width: column.width
                compact: true
                dismissOnClick: true
                notification: modelData
                onDismissed: root.popAt(index)

                Timer {
                    running: modelData.urgency !== NotificationUrgency.Critical
                    interval: modelData.urgency === NotificationUrgency.Low ? 3000 : 5000
                    onTriggered: root.popAt(index)
                }

                // the underlying Notification can be destroyed out from under us
                // (e.g. "clear all" dismisses it while it's still shown as a toast) -
                // drop it from the queue immediately so nothing touches freed memory
                Connections {
                    target: modelData
                    function onClosed() {
                        root.remove(modelData)
                    }
                }
            }
        }
    }
}
