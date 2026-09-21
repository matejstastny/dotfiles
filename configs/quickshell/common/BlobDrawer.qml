import QtQuick
import "../"

// a panel that lives behind one side of the frame and slides inwards. it is an
// ordinary shape in the blob field, so the whole effect is just where it parks:
// buried in the band, the two share a surface, and opening it looks like the
// outline stretching rather than a card appearing on top of one
BlobRect {
    id: root

    property string edge: "top"
    property bool open: false

    // the region inside the frame, in group coordinates - the drawer centres
    // itself on the side it comes from and rests flush against it
    property rect area: Qt.rect(0, 0, 0, 0)

    // 0 parked, 1 fully out. the spatial curve overshoots, so it carries past
    // flush and settles back, which is what makes the surface read as elastic
    property real progress: open ? 1 : 0

    readonly property bool horizontal: edge === "left" || edge === "right"
    readonly property real travel: (horizontal ? width : height) + theme.drawerPark

    radius: theme.frameRadius
    deformScale: theme.drawerDeformScale

    // the edge it comes out of is squared off. a radius there leaves a notch at
    // each end of the join for the blend to fill, and the drawer reads as glued
    // onto the bar rather than drawn out of it
    topLeftRadius: edge === "top" || edge === "left" ? 0 : -1
    topRightRadius: edge === "top" || edge === "right" ? 0 : -1
    bottomLeftRadius: edge === "bottom" || edge === "left" ? 0 : -1
    bottomRightRadius: edge === "bottom" || edge === "right" ? 0 : -1

    visible: open || progress > 0.001
    opacity: Math.max(0, Math.min(1, progress))

    x: {
        if (edge === "left")
            return area.x - travel * (1 - progress);
        if (edge === "right")
            return area.x + area.width - width + travel * (1 - progress);
        return area.x + (area.width - width) / 2;
    }

    y: {
        if (edge === "top")
            return area.y - travel * (1 - progress);
        if (edge === "bottom")
            return area.y + area.height - height + travel * (1 - progress);
        return area.y + (area.height - height) / 2;
    }

    Behavior on progress {
        NumberAnimation {
            duration: root.theme.drawerDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.theme.easingDrawer
        }
    }
}
