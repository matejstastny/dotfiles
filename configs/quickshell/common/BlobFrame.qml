import QtQuick
import "../"

// the screen outline, as a hole cut in a slab rather than another blob: it is
// subtracted from the field instead of added to it, which is what lets drawers
// share its surface. assign it to a BlobGroup's `frame` and keep it a direct
// child - the group reads its geometry straight off, no mapping
Item {
    id: root

    property real borderLeft: Theme.frameThickness
    property real borderRight: Theme.frameThickness
    property real borderTop: Theme.frameThickness
    property real borderBottom: Theme.frameThickness
    property real radius: Theme.frameRadius
}
