import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"

// layershell only honours an exclusive zone on a surface anchored to a single
// edge, and Surface is anchored to all four - so the space the outline takes up
// is reserved by four throwaway windows instead, one per side
Scope {
    id: root

    required property var screen

    component Edge: PanelWindow {
        screen: root.screen
        color: "transparent"
        implicitWidth: 1
        implicitHeight: 1
        focusable: false
        mask: Region {}

        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell:exclusion"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    }

    Edge {
        anchors.top: true
        exclusiveZone: Theme.barHeight
    }
    Edge {
        anchors.bottom: true
        exclusiveZone: Theme.frameThickness
    }
    Edge {
        anchors.left: true
        exclusiveZone: Theme.frameThickness
    }
    Edge {
        anchors.right: true
        exclusiveZone: Theme.frameThickness
    }
}
