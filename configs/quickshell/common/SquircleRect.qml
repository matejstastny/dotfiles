import QtQuick
import "../"

ShaderEffect {
    id: root

    readonly property Theme theme: Theme {}

    property color color: "transparent"
    property color borderColor: "transparent"
    property real radius: 0
    property real borderWidth: 0
    property real smoothing: root.theme.smoothing

    property size size: Qt.size(width, height)
    property color fillColor: root.color

    Behavior on radius {
        NumberAnimation {
            duration: root.theme.spatialDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.theme.easingSpatial
        }
    }
    Behavior on color {
        ColorAnimation {
            duration: root.theme.effectsDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.theme.easingEffects
        }
    }
    Behavior on borderColor {
        ColorAnimation {
            duration: root.theme.effectsDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.theme.easingEffects
        }
    }

    vertexShader: Qt.resolvedUrl("../shaders/squircle.vert.qsb")
    fragmentShader: Qt.resolvedUrl("../shaders/squircle.frag.qsb")
}
