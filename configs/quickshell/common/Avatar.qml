import QtQuick
import QtQuick.Effects

Item {
    id: root

    property string source: ""
    property int size: 40

    implicitWidth: size
    implicitHeight: size

    Image {
        id: img
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        smooth: true
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: mask
        }
    }

    Item {
        id: mask
        width: img.width
        height: img.height
        visible: false
        layer.enabled: true
        Rectangle {
            anchors.fill: parent
            radius: width / 2
        }
    }
}
