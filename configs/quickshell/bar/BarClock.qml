import QtQuick
import "../"

Item {
    id: root

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
        color: Theme.text
        font.pixelSize: Theme.barFontSize
        font.family: Theme.fontMono
        font.weight: Font.Normal

    }
}
