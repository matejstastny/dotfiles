import QtQuick
import "../"

Item {
    id: root

    readonly property Theme theme: Theme {}
    property date now: new Date()
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: Qt.formatDateTime(root.now, "hh:mm")
        color: theme.text
        font.pixelSize: theme.barFontSize
        font.family: theme.fontFamily
        font.weight: Font.Normal

    }
}
