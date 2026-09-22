import QtQuick
import "../"

ShaderEffect {
    id: root

    property color color: "transparent"
    property color borderColor: "transparent"
    property real radius: 0
    property real borderWidth: 0
    property real smoothing: Theme.smoothing
    property bool animateColor: true

    property size size: Qt.size(width, height)
    property color fillColor: root.color

    Behavior on radius {
        NumberAnimation {
            duration: Theme.spatialDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.easingSpatial
        }
    }
    Behavior on color {
        enabled: root.animateColor
        ColorAnimation {
            duration: Theme.effectsDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.easingEffects
        }
    }
    Behavior on borderColor {
        ColorAnimation {
            duration: Theme.effectsDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.easingEffects
        }
    }

    vertexShader: Qt.resolvedUrl("../shaders/squircle.vert.qsb")
    fragmentShader: Qt.resolvedUrl("../shaders/squircle.frag.qsb")
}
