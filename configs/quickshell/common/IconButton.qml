import QtQuick
import "../"

Item {
    id: root

    property string icon: ""
    property string label: ""
    property int iconSize: 18
    property bool active: false
    property bool danger: false
    signal clicked()

    implicitWidth: 96
    implicitHeight: 56

    SquircleRect {
        anchors.fill: parent
        radius: mouseArea.pressed ? Theme.radiusPressed : (root.active ? Theme.radiusActive : Theme.radiusRest)
        color: root.active ? Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.18) : Theme.surface
        // changing keyboard selection must not retarget a half-finished fill
        // animation, which is what caused the purple flash in the power menu
        animateColor: false
        borderWidth: Theme.borderWidth
        borderColor: mouseArea.containsMouse ? Theme.purple : Theme.muted

        Column {
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.icon
                color: root.danger ? Theme.rose : (root.active ? Theme.purple : Theme.text)
                font.pixelSize: root.iconSize
                font.family: Theme.fontMono
                Behavior on color { ColorAnimation { duration: 100; easing.type: Easing.OutCubic } }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.label.length > 0
                text: root.label
                color: Theme.dim
                font.pixelSize: 10
                font.family: Theme.fontMono
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
            duration: Theme.spatialDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.easingSpatial
        }
    }
}
