import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../"

PanelWindow {
    id: root

    property bool open: false
    signal closeRequested()

    required property string popoutName
    property bool centered: true
    // a centered popup that resizes with its content would otherwise drag its
    // own header up and down as the card re-centers. pinTop fixes the card's
    // top edge inside the (constant-size) window so it only ever grows down
    property bool pinTop: false
    property string keyboardFocusMode: "exclusive"
    property string title: ""
    property int popupWidth: 400
    property int popupHeight: 400
    // how the card follows a popupWidth/popupHeight change. springy by
    // default, since most popups only size once as they open
    property int resizeDuration: theme.spatialDuration
    property var resizeEasing: theme.easingSpatial

    readonly property Theme theme: Theme {}
    readonly property int shadowPad: 84
    readonly property int shadowSpread: 68

    // anchored (non-centered) popups grow out of the top-right corner
    // they're triggered from, instead of fading in centered like a dialog -
    // the seed size roughly matches the bar icon that opens them
    readonly property bool growFromAnchor: !root.centered
    readonly property bool anchorTop: root.centered && root.pinTop
    readonly property int seedSize: 40
    readonly property int curWidth: root.growFromAnchor ? (root.open ? popupWidth : seedSize) : popupWidth
    readonly property int curHeight: root.growFromAnchor ? (root.open ? popupHeight : seedSize) : popupHeight

    default property alias content: contentArea.data

    visible: card.opacity > 0.001
    color: "transparent"
    implicitWidth: popupWidth + shadowPad * 2
    implicitHeight: popupHeight + shadowPad * 2
    exclusiveZone: 0

    mask: Region { item: card }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:" + root.popoutName
    WlrLayershell.keyboardFocus: root.open
        ? (root.keyboardFocusMode === "exclusive" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand)
        : WlrKeyboardFocus.None
    focusable: false

    HyprlandFocusGrab {
        active: root.open
        windows: [QsWindow.window]
        onCleared: root.closeRequested()
    }

    onOpenChanged: {
        if (root.open) PopoutState.current = root.popoutName
        else if (PopoutState.current === root.popoutName) PopoutState.current = ""
    }
    Connections {
        target: PopoutState
        function onCurrentChanged() {
            if (PopoutState.current !== root.popoutName && root.open) root.closeRequested()
        }
    }

    anchors {
        top: !root.centered
        right: !root.centered
    }
    margins {
        top: root.centered ? 0 : 10 - shadowPad
        right: root.centered ? 0 : 10 - shadowPad
    }

    // shadow is cast from its own padded item, not from `card` directly -
    // a layer.effect's texture is sized to its own item, so blur applied
    // straight to `card` has no room to bleed past its edges and gets clipped.
    //
    // shadowColor is purple, not black: this overlay layer composites with
    // additive blending, so a black shadow contributes nothing and is
    // invisible at any opacity - only a colored glow actually shows up
    Item {
        id: shadowCaster
        anchors.centerIn: root.centered && !root.pinTop ? parent : undefined
        anchors.horizontalCenter: root.anchorTop ? parent.horizontalCenter : undefined
        anchors.top: root.centered && !root.anchorTop ? undefined : parent.top
        anchors.right: root.centered ? undefined : parent.right
        anchors.topMargin: shadowPad - shadowSpread
        anchors.rightMargin: root.centered ? 0 : shadowPad - shadowSpread
        width: root.curWidth + shadowSpread * 2
        height: root.curHeight + shadowSpread * 2
        z: -1

        opacity: card.opacity
        scale: card.scale

        Behavior on width { NumberAnimation { duration: root.resizeDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.resizeEasing } }
        Behavior on height { NumberAnimation { duration: root.resizeDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.resizeEasing } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#9d79d6"
            blurMax: 64
            shadowBlur: 1.0
            shadowVerticalOffset: 6
            shadowHorizontalOffset: 0
            shadowOpacity: 0.9
        }

        Rectangle {
            anchors.centerIn: parent
            width: root.curWidth
            height: root.curHeight
            radius: theme.radius
            color: "black"
        }
    }

    SquircleRect {
        id: card
        anchors.centerIn: root.centered && !root.pinTop ? parent : undefined
        anchors.horizontalCenter: root.anchorTop ? parent.horizontalCenter : undefined
        anchors.top: root.centered && !root.anchorTop ? undefined : parent.top
        anchors.right: root.centered ? undefined : parent.right
        anchors.topMargin: shadowPad
        anchors.rightMargin: root.centered ? 0 : shadowPad
        width: root.curWidth
        height: root.curHeight
        radius: root.growFromAnchor && !root.open ? theme.radiusRest : theme.radius
        color: theme.base
        borderWidth: theme.borderWidth
        borderColor: theme.muted
        clip: true

        opacity: root.open ? 1 : 0
        scale: root.growFromAnchor ? 1 : (root.open ? 1 : 0.96)

        Behavior on width { NumberAnimation { duration: root.resizeDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.resizeEasing } }
        Behavior on height { NumberAnimation { duration: root.resizeDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.resizeEasing } }
        Behavior on opacity { NumberAnimation { duration: theme.effectsDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: theme.easingEffects } }
        Behavior on scale { NumberAnimation { duration: theme.popDuration; easing.type: Easing.OutBack; easing.overshoot: theme.popOvershoot } }

        Item {
            id: header
            visible: root.title.length > 0
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            height: visible ? 18 : 0
            opacity: root.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: theme.effectsDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: theme.easingEffects } }

            Text {
                id: titleText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "✦ " + root.title
                color: theme.purple
                font.pixelSize: 15
                font.bold: true
                font.family: theme.fontFamily
                font.weight: Font.Normal
            }
        }

        Item {
            id: contentArea
            anchors.top: header.visible ? header.bottom : parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 16
            anchors.topMargin: header.visible ? 14 : 16
            opacity: root.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: theme.effectsDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: theme.easingEffects } }
        }
    }
}
