import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    required property string script
    required property int interval
    property string onClickCommand: ""

    readonly property Theme theme: Theme {}
    property string text: ""
    property string tooltip: ""

    visible: text !== ""
    implicitWidth: visible ? label.implicitWidth + 8 : 0
    implicitHeight: 38

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
        color: theme.text
        font.pixelSize: 15
        font.family: theme.fontFamily
        font.weight: Font.Normal
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: root.onClickCommand !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: root.onClickCommand !== ""
        onClicked: Quickshell.execDetached(["sh", "-c", root.onClickCommand])
    }
}
