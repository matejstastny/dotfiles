pragma Singleton

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

    readonly property int radius: 15
    readonly property int radiusSmall: 8

    // maple, everywhere, on purpose. the split is kept because the call sites
    // are already tagged by job - fontMono for readouts and anything you type
    // into, fontSans for prose (notification bodies, media titles, headings) -
    // so pointing prose at a different family is a one-line change here rather
    // than a sweep. it is not an invitation to actually do that
    readonly property string fontMono: "Maple Mono NF"
    readonly property string fontSans: "Maple Mono NF"

    // font.bold and font.weight write the same underlying value, so setting
    // both leaves whichever came last standing. only weight is used anywhere
    // in the shell now
    readonly property int weightBody: Font.Normal
    readonly property int weightMedium: Font.Medium
    readonly property int weightHeading: Font.DemiBold

    // five steps, and every text in the shell picks one of them. the point of
    // a scale is that there is nowhere else to go: a literal pixelSize at a
    // call site is how the last one drifted into eleven different sizes
    readonly property int sizeMicro: 10
    readonly property int sizeLabel: 11
    readonly property int sizeBody: 13
    readonly property int sizeTitle: 15
    readonly property int sizeInput: 16

    // glyph sizes are their own scale. a nerd-font icon set to sizeBody does
    // not read as the same weight as 13px of prose next to it, so icons never
    // borrow a step from the text scale
    readonly property int iconSmall: 14
    readonly property int iconBody: 16
    readonly property int iconLarge: 20
    readonly property int iconHuge: 30

    // one spacing ramp, same reasoning as the type scale
    readonly property int gapSmall: 6
    readonly property int gap: 10
    readonly property int gapLarge: 14
    readonly property int padding: 16
    readonly property int paddingLarge: 20

    // list metrics. every list in the shell is this tall per row and hangs its
    // text off this gutter, so a picker and the launcher read as one surface
    // with different contents rather than two programs
    readonly property int rowHeight: 32
    readonly property int rowGutter: 22
    readonly property int markerWidth: 2
    readonly property int markerHeight: 16

    readonly property int barFontSize: 14
    readonly property int barModuleHeight: 38
    readonly property int borderWidth: 1
    readonly property int transitionDuration: 140
    readonly property int barHeight: 37

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

    // motion that re-fires while a surface is already open (a launcher
    // resizing on every keystroke) gets this instead: short, and paired with
    // easingEffects so it decelerates flat rather than springing past itself.
    // the overshoot is a nice greeting, it is not something to sit through
    // three times a second
    readonly property int snapDuration: 120

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
    readonly property int drawerPark: 4

    // drawers get their own motion: easingSpatial overshoots by about 8%, which
    // is a pleasant nudge on a button and a 50px lurch on something 600px tall.
    // this curve settles about 1.5% past flush instead, and the deform is halved
    // so the spring has less to ring out once the slide has finished
    readonly property int drawerDuration: 220
    // drawers should feel fluid without visibly stretching past their final size
    readonly property var easingDrawer: [0.25, 1.08, 0.45, 1.0, 1.0, 1.0]
    readonly property real drawerDeformScale: blobDeformScale * 0.5

    // the command surface - launcher and every picker - is not a dialog. it
    // drops out from under the bar, squared off where the two meet, so it reads
    // as the bar extending downwards rather than a card floating over the
    // desktop. one width and one row budget for all of them: whichever keybind
    // you hit, the answer appears in the same place at the same size
    readonly property int commandWidth: 560
    readonly property int commandMaxRows: 8

    // hyprland drops a focus grab the moment a key event lands that is not for
    // the grabbing surface, and the keybind that opened the surface is still
    // physically held at that point. arming the grab this late lets the whole
    // chord finish first
    readonly property int grabArmDelay: 150

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
