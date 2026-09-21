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
    readonly property int barHeight: 37
    readonly property int popDuration: 260
    readonly property real popOvershoot: 1.35

    // motion: "spatial" changes (position/size/shape) get a springy
    // overshoot, "effects" changes (opacity/color) get a plain decel -
    // mixing curves like this is what keeps constant fades from feeling
    // like they belong to the same motion as a button growing into a panel
    // Easing.BezierSpline wants a full [c1x,c1y, c2x,c2y, endx,endy] segment
    // ending at (1,1), not a 4-number CSS cubic-bezier() tuple - the first
    // four numbers here ARE that cubic-bezier(), just with (1,1) appended
    readonly property var easingSpatial: [0.34, 1.56, 0.64, 1.0, 1.0, 1.0]
    readonly property var easingEffects: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
    readonly property int spatialDuration: 320
    readonly property int effectsDuration: 160

    // squircle (superellipse) corner smoothing, used by SquircleRect -
    // 0 = plain circular corner, 1 = continuous "iOS-style" corner
    readonly property real smoothing: 0.6

    // blob field: the bar and everything hanging off it are one merged SDF
    // surface, so popouts ooze out of the bar instead of appearing beside it.
    // blobSmoothing is the fillet radius of the join, blobOverlap is how far a
    // popout's top edge sinks into the bar before it starts emerging
    readonly property int blobSmoothing: 20
    readonly property int blobOverlap: 8

    // the screen outline is part of that same field, not a separate decoration:
    // the bar is its top side, and a drawer parked behind any side shares its
    // skin, so opening one looks like the outline being pulled inwards.
    // frameRadius rounds the inner corners only - the outer edge is the screen
    readonly property int frameThickness: 10
    readonly property int frameRadius: 25

    // how far a closed drawer sits behind the outline. deep enough that the
    // blend has nothing left to round off, shallow enough that the pocket the
    // band opens for it never shows
    readonly property int drawerPark: 5

    // drawers get their own motion: easingSpatial overshoots by about 8%, which
    // is a pleasant nudge on a button and a 50px lurch on something 600px tall.
    // this curve settles about 1.5% past flush instead, and the deform is halved
    // so the spring has less to ring out once the slide has finished
    readonly property int drawerDuration: 220
    // drawers should feel fluid without visibly stretching past their final size
    readonly property var easingDrawer: [0.25, 1.08, 0.45, 1.0, 1.0, 1.0]
    readonly property real drawerDeformScale: blobDeformScale * 0.5

    // toasts share one panel rather than getting a blob each, so the left edge
    // stays a straight run instead of pinching at every divider
    readonly property int toastWidth: 340
    readonly property int maxToasts: 5

    // velocity-driven squash: deformScale converts px/s into stretch, capped at
    // 35%, and the spring is underdamped so it overshoots back to rest
    readonly property real blobStiffness: 200
    readonly property real blobDamping: 16
    readonly property real blobDeformScale: 0.00008

    // shape-morph radii for interactive elements (IconButton etc.) -
    // pressed squishes squarer, focused/active opens rounder
    readonly property int radiusPressed: 10
    readonly property int radiusRest: 16
    readonly property int radiusActive: 24
}
