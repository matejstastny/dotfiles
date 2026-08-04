import QtQuick
import "../"

Item {
    id: root

    signal clicked()

    readonly property Theme theme: Theme {}
    property date now: new Date()
    readonly property bool hovered: hoverArea.containsMouse

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
        text: Qt.formatDateTime(root.now, "MM/dd · hh:mm")
        color: root.hovered ? theme.bright : theme.text
        font.pixelSize: theme.barFontSize
        font.family: theme.fontFamily
        font.weight: Font.Normal

        Behavior on color { ColorAnimation { duration: theme.transitionDuration } }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
