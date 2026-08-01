import QtQuick

Item {
    id: root

    signal clicked()

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
        text: Qt.formatDateTime(root.now, "ddd dd · hh:mm")
        color: theme.text
        font.pixelSize: 15
        font.family: theme.fontFamily
        font.weight: Font.Normal
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
