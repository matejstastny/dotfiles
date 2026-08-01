import QtQuick
import Quickshell

Item {
    id: root

    property Item anchorItem: null
    property var menuHandle: null
    property bool menuOpen: false

    readonly property Theme theme: Theme {}

    function open() { root.menuOpen = true }
    function close() { root.menuOpen = false }
    function toggle() { root.menuOpen = !root.menuOpen }

    QsMenuOpener {
        id: opener
        menu: root.menuHandle
    }

    Rectangle {
        id: box
        visible: root.menuOpen
        y: 38
        x: -80
        width: 220
        height: Math.min(300, list.implicitHeight + 12)
        radius: theme.radiusSmall
        color: theme.surface
        border.width: 1
        border.color: theme.muted
        clip: true

        Column {
            id: list
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            spacing: 2

            Repeater {
                model: opener.children ? opener.children.values : []
                delegate: Item {
                    required property var modelData
                    width: list.width
                    height: modelData.isSeparator ? 8 : 26

                    Rectangle {
                        visible: modelData.isSeparator
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 1
                        color: theme.muted
                    }

                    Text {
                        visible: !modelData.isSeparator
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 8
                        text: modelData.text
                        color: modelData.enabled ? theme.text : theme.muted
                        font.pixelSize: 12
                        font.family: theme.fontFamily
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        visible: !modelData.isSeparator
                        anchors.fill: parent
                        enabled: modelData.enabled
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            modelData.triggered()
                            root.close()
                        }
                    }
                }
            }
        }
    }
}
