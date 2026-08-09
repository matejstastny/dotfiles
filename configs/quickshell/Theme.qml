import QtQuick

QtObject {
    readonly property color base: "#11111b"
    readonly property color surface: "#181825"
    readonly property color overlay: "#25253a"
    readonly property color muted: "#3d3d5c"
    readonly property color purple: "#7878c8"
    readonly property color rose: "#c47ab8"
    readonly property color text: "#dce0f4"
    readonly property color dim: "#9898c0"
    readonly property color bright: "#f0f0ff"

    readonly property int radius: 14
    readonly property int radiusSmall: 8
    readonly property string fontFamily: "Maple Mono NF"
    readonly property int barFontSize: 14
    readonly property int barModuleHeight: 38
    readonly property int borderWidth: 1
    readonly property int transitionDuration: 140
    readonly property int barHeight: 35
    readonly property int popDuration: 260
    readonly property real popOvershoot: 1.35
}
