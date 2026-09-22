import QtQuick
import QtQuick.Effects

// an image clipped to rounded corners. `clip` is rectangular and ignores a
// Rectangle's radius, so the only way to actually round an image in qt6 is to
// mask it against a shape drawn in an offscreen layer
Item {
    id: root

    property alias source: img.source
    property alias fillMode: img.fillMode
    property alias status: img.status
    // defaults to a circle, since that is what most callers want
    property real radius: Math.min(width, height) / 2

    Image {
        id: img

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        // never decode larger than it is drawn - album art arrives at whatever
        // size the player felt like sending
        sourceSize.width: Math.max(1, Math.ceil(root.width))
        sourceSize.height: Math.max(1, Math.ceil(root.height))

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
            radius: root.radius
        }
    }
}
