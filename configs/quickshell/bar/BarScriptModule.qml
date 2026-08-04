import QtQuick
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: root

    required property string script
    required property int interval
    property string onClickCommand: ""

    readonly property Theme theme: Theme {}
    property string text: ""
    property string tooltip: ""
    property string statusClass: ""
    readonly property bool hovered: hoverArea.containsMouse
    readonly property bool active: statusClass === "recording" || statusClass === "connected" || statusClass === "running"

    visible: text !== ""
    implicitWidth: visible ? label.implicitWidth + 8 : 0
    implicitHeight: theme.barModuleHeight

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: [root.script]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const parsed = JSON.parse(data)
                    root.text = parsed.text || ""
                    root.tooltip = parsed.tooltip || ""
                    root.statusClass = parsed.class || ""
                } catch (e) {
                    root.text = ""
                }
            }
        }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.statusClass === "recording" ? theme.rose
             : (root.active ? theme.purple : theme.dim)
        font.pixelSize: theme.barFontSize
        font.family: theme.fontFamily
        font.weight: Font.Normal

        Behavior on color { ColorAnimation { duration: theme.transitionDuration } }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.onClickCommand !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: root.onClickCommand !== ""
        onClicked: Quickshell.execDetached(["sh", "-c", root.onClickCommand])
    }
}
