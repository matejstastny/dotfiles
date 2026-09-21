import QtQuick
import "../"

// the screen outline, as a hole cut in a slab rather than another blob: it is
// subtracted from the field instead of added to it, which is what lets drawers
// share its surface. assign it to a BlobGroup's `frame` and keep it a direct
// child - the group reads its geometry straight off, no mapping
Item {
    id: root

    readonly property Theme theme: Theme {}

    property real borderLeft: theme.frameThickness
    property real borderRight: theme.frameThickness
    property real borderTop: theme.frameThickness
    property real borderBottom: theme.frameThickness
    property real radius: theme.frameRadius
}
