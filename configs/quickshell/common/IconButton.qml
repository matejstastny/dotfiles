import QtQuick
import "../"

Item {
    id: root

    property string icon: ""
    property string label: ""
    property bool active: false
    property bool danger: false
    signal clicked()

    readonly property Theme theme: Theme {}

    implicitWidth: 96
    implicitHeight: 56

    SquircleRect {
        anchors.fill: parent
        radius: mouseArea.pressed ? theme.radiusPressed : (root.active ? theme.radiusActive : theme.radiusRest)
        color: root.active ? Qt.rgba(theme.purple.r, theme.purple.g, theme.purple.b, 0.18) : theme.surface
        borderWidth: theme.borderWidth
        borderColor: mouseArea.containsMouse ? theme.purple : theme.muted

        Column {
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.icon
                color: root.danger ? theme.rose : (root.active ? theme.purple : theme.text)
                font.pixelSize: 18
                font.family: theme.fontFamily
                Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.label
                color: theme.dim
                font.pixelSize: 10
                font.family: theme.fontFamily
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    scale: mouseArea.pressed ? 0.96 : (mouseArea.containsMouse ? 1.04 : 1)
    Behavior on scale {
        NumberAnimation {
            duration: theme.spatialDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: theme.easingSpatial
        }
    }
}
