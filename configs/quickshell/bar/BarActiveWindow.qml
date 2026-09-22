import QtQuick
import Quickshell.Wayland
import "../"

Item {
    id: root

    readonly property var toplevel: ToplevelManager.activeToplevel
    readonly property string appName: root.toplevel ? (root.toplevel.appId || root.toplevel.title || "") : ""
    readonly property int maxLabelWidth: 220

    visible: root.appName !== ""
    implicitWidth: visible ? Math.min(label.implicitWidth, root.maxLabelWidth) + 8 : 0
    implicitHeight: Theme.barModuleHeight

    Text {
        id: label
        anchors.centerIn: parent
        width: Math.min(implicitWidth, root.maxLabelWidth)
        text: root.appName
        color: Theme.dim
        font.pixelSize: Theme.barFontSize - 1
        font.family: Theme.fontMono
        font.weight: Font.Normal
        elide: Text.ElideRight
    }
}
