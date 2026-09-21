import QtQuick
import "../"

Item {
    id: root

    readonly property Theme theme: Theme {}

    // Qt 6 cannot bind a uniform array from QML, so the field is a fixed set of
    // slots rather than caelestia's dynamic rect list
    readonly property int slotCount: 8

    property color color: theme.base
    property color borderColor: "transparent"
    property real borderWidth: 0
    property real smoothing: theme.blobSmoothing
    property list<Item> shapes

    // at most one BlobFrame, and it has to be a direct child: its geometry is
    // bound rather than mapped per frame, since unlike the shapes it never
    // moves under an ancestor that could shift without notifying
    property Item frame

    readonly property vector4d frameOuter: frame ? Qt.vector4d(frame.x + frame.width / 2, frame.y + frame.height / 2, frame.width / 2, frame.height / 2) : Qt.vector4d(0, 0, 0, 0)

    readonly property vector4d frameInner: {
        if (!frame)
            return Qt.vector4d(0, 0, 0, 0);
        const left = frame.x + frame.borderLeft;
        const right = frame.x + frame.width - frame.borderRight;
        const top = frame.y + frame.borderTop;
        const bottom = frame.y + frame.height - frame.borderBottom;
        return Qt.vector4d((left + right) / 2, (top + bottom) / 2, (right - left) / 2, (bottom - top) / 2);
    }

    // the field is drawn by a node per shape plus four for the frame, rather
    // than one quad over the whole surface. the shader is the same either way,
    // but a screen-sized quad costs screen-sized fragment work on every repaint
    // of the window - and `discard` stops a tile-based gpu culling any of it.
    // each node rasterises only its own neighbourhood and drops the pixels it
    // does not own, so the cost tracks the shapes instead of the display
    readonly property real quadPad: smoothing * 1.5

    // where a shape's node has to reach to: the blend radius, plus room for the
    // sdf scaling that a squashed shape introduces
    property var slotQuads: []

    // the ring outside this box is the frame's, carved into four bands that
    // tile it without overlapping - they share an owner, so they must not
    readonly property real bandTop: frame ? Math.max(0, Math.min(height, frameInner.y - frameInner.w + quadPad)) : 0
    readonly property real bandBottom: frame ? Math.min(height, Math.max(0, frameInner.y + frameInner.w - quadPad)) : 0
    readonly property real bandLeft: frame ? Math.max(0, Math.min(width, frameInner.x - frameInner.z + quadPad)) : 0
    readonly property real bandRight: frame ? Math.min(width, Math.max(0, frameInner.x + frameInner.z - quadPad)) : 0

    // uniform mirrors. qml cannot share one buffer between ShaderEffects, so
    // sync writes them here once and every node binds them
    property vector4d box0: Qt.vector4d(0, 0, 0, 0)
    property vector4d box1: Qt.vector4d(0, 0, 0, 0)
    property vector4d box2: Qt.vector4d(0, 0, 0, 0)
    property vector4d box3: Qt.vector4d(0, 0, 0, 0)
    property vector4d box4: Qt.vector4d(0, 0, 0, 0)
    property vector4d box5: Qt.vector4d(0, 0, 0, 0)
    property vector4d box6: Qt.vector4d(0, 0, 0, 0)
    property vector4d box7: Qt.vector4d(0, 0, 0, 0)

    property vector4d rad0: Qt.vector4d(0, 0, 0, 0)
    property vector4d rad1: Qt.vector4d(0, 0, 0, 0)
    property vector4d rad2: Qt.vector4d(0, 0, 0, 0)
    property vector4d rad3: Qt.vector4d(0, 0, 0, 0)
    property vector4d rad4: Qt.vector4d(0, 0, 0, 0)
    property vector4d rad5: Qt.vector4d(0, 0, 0, 0)
    property vector4d rad6: Qt.vector4d(0, 0, 0, 0)
    property vector4d rad7: Qt.vector4d(0, 0, 0, 0)

    property vector4d def0: Qt.vector4d(1, 0, 1, 1)
    property vector4d def1: Qt.vector4d(1, 0, 1, 1)
    property vector4d def2: Qt.vector4d(1, 0, 1, 1)
    property vector4d def3: Qt.vector4d(1, 0, 1, 1)
    property vector4d def4: Qt.vector4d(1, 0, 1, 1)
    property vector4d def5: Qt.vector4d(1, 0, 1, 1)
    property vector4d def6: Qt.vector4d(1, 0, 1, 1)
    property vector4d def7: Qt.vector4d(1, 0, 1, 1)

    readonly property bool animating: {
        for (let i = 0; i < shapes.length; i++) {
            const shape = shapes[i];
            if (shape && !shape.blobStatic && shape.visible)
                return true;
        }
        return false;
    }

    onAnimatingChanged: sync(0)
    onShapesChanged: sync(0)
    onWidthChanged: sync(0)
    onHeightChanged: sync(0)
    Component.onCompleted: sync(0)

    FrameAnimation {
        running: root.animating
        onTriggered: root.sync(frameTime)
    }

    function smoothstep(edge0: real, edge1: real, x: real): real {
        const t = Math.max(0, Math.min(1, (x - edge0) / (edge1 - edge0)));
        return t * t * (3 - 2 * t);
    }

    function sdBox(px: real, py: real, box: var): real {
        const dx = Math.abs(px - box.cx) - box.hw;
        const dy = Math.abs(py - box.cy) - box.hh;
        return Math.sqrt(Math.max(dx, 0) ** 2 + Math.max(dy, 0) ** 2) + Math.min(Math.max(dx, dy), 0);
    }

    // a corner sitting on a neighbour's edge gets squared off so the junction
    // reads as one surface; far outside the neighbour, or buried deep inside it,
    // the corner keeps its full radius
    function cornerRadii(boxes: var, index: int): vector4d {
        const self = boxes[index];
        const base = self.shape.packedRadii;
        const cornerX = [self.cx + self.hw, self.cx + self.hw, self.cx - self.hw, self.cx - self.hw];
        const cornerY = [self.cy - self.hh, self.cy + self.hh, self.cy + self.hh, self.cy - self.hh];
        const factors = [1, 1, 1, 1];

        for (let j = 0; j < boxes.length; j++) {
            if (j === index || !boxes[j])
                continue;
            for (let k = 0; k < 4; k++) {
                const sd = sdBox(cornerX[k], cornerY[k], boxes[j]);
                factors[k] = Math.min(factors[k], Math.max(smoothstep(0, smoothing, sd), smoothstep(0, -smoothing, sd)));
            }
        }

        return Qt.vector4d(squashed(base.x, factors[0]), squashed(base.y, factors[1]), squashed(base.z, factors[2]), squashed(base.w, factors[3]));
    }

    // the floor stops a squashed corner collapsing the sdf, but it must never
    // raise a corner that was asked for square in the first place - that is what
    // welds a drawer flat onto the bar instead of pinching at the join
    function squashed(base: real, factor: real): real {
        return Math.min(base, Math.max(base * factor, 2));
    }

    // the axis-aligned box the deformed shape actually occupies, grown by the
    // blend. anything further out cannot be this shape's to paint
    function quadFor(box: var): rect {
        const shape = box.shape;
        const ex = Math.abs(shape.m00) * box.hw + Math.abs(shape.m01) * box.hh + quadPad;
        const ey = Math.abs(shape.m01) * box.hw + Math.abs(shape.m11) * box.hh + quadPad;
        const x0 = Math.max(0, box.cx - ex);
        const y0 = Math.max(0, box.cy - ey);
        const x1 = Math.min(width, box.cx + ex);
        const y1 = Math.min(height, box.cy + ey);
        return Qt.rect(x0, y0, Math.max(0, x1 - x0), Math.max(0, y1 - y0));
    }

    function sync(dt: real): void {
        const boxes = [];
        for (let i = 0; i < slotCount; i++) {
            const shape = i < shapes.length ? shapes[i] : null;
            if (!shape || !shape.visible || shape.width <= 0 || shape.height <= 0) {
                boxes.push(null);
                continue;
            }
            // ancestors move without notifying, so the mapping is recomputed each
            // frame rather than bound
            const centre = shape.mapToItem(root, shape.width / 2, shape.height / 2);
            boxes.push({
                shape: shape,
                cx: centre.x,
                cy: centre.y,
                hw: shape.width / 2,
                hh: shape.height / 2
            });
        }

        if (dt > 0)
            for (let i = 0; i < boxes.length; i++)
                if (boxes[i])
                    boxes[i].shape.step(dt, boxes[i].cx, boxes[i].cy);

        const quads = [];
        for (let i = 0; i < slotCount; i++) {
            const box = boxes[i];
            if (!box) {
                root["box" + i] = Qt.vector4d(0, 0, 0, 0);
                quads.push(Qt.rect(0, 0, 0, 0));
                continue;
            }
            root["box" + i] = Qt.vector4d(box.cx, box.cy, box.hw, box.hh);
            root["rad" + i] = cornerRadii(boxes, i);
            root["def" + i] = box.shape.packedDeform;
            quads.push(quadFor(box));
        }
        slotQuads = quads;
    }

    Repeater {
        model: root.slotCount

        delegate: FieldQuad {
            id: slot

            required property int index
            readonly property rect area: index < root.slotQuads.length ? root.slotQuads[index] : Qt.rect(0, 0, 0, 0)

            ownerIndex: slot.index
            visible: slot.area.width > 0 && slot.area.height > 0
            x: slot.area.x
            y: slot.area.y
            width: slot.area.width
            height: slot.area.height
        }
    }

    FieldQuad {
        ownerIndex: -1
        visible: root.bandTop > 0
        width: root.width
        height: root.bandTop
    }

    FieldQuad {
        ownerIndex: -1
        visible: root.frame && root.bandBottom < root.height
        y: root.bandBottom
        width: root.width
        height: root.height - root.bandBottom
    }

    FieldQuad {
        ownerIndex: -1
        visible: root.bandLeft > 0 && root.bandBottom > root.bandTop
        y: root.bandTop
        width: root.bandLeft
        height: root.bandBottom - root.bandTop
    }

    FieldQuad {
        ownerIndex: -1
        visible: root.frame && root.bandRight < root.width && root.bandBottom > root.bandTop
        x: root.bandRight
        y: root.bandTop
        width: root.width - root.bandRight
        height: root.bandBottom - root.bandTop
    }

    component FieldQuad: ShaderEffect {
        // -1 paints the frame, 0..slotCount-1 paints that shape. every node sees
        // the whole field, so the picture is identical whichever one draws it
        property real ownerIndex: -1

        property vector4d quad: Qt.vector4d(x, y, width, height)

        property real smoothing: root.smoothing
        property real borderWidth: root.borderWidth
        property real frameEnabled: root.frame && root.frame.visible ? 1 : 0
        property real frameRadius: root.frame ? root.frame.radius : 0
        property color fillColor: root.color
        property color borderColor: root.borderColor
        property vector4d frameOuter: root.frameOuter
        property vector4d frameInner: root.frameInner

        property vector4d box0: root.box0
        property vector4d box1: root.box1
        property vector4d box2: root.box2
        property vector4d box3: root.box3
        property vector4d box4: root.box4
        property vector4d box5: root.box5
        property vector4d box6: root.box6
        property vector4d box7: root.box7

        property vector4d rad0: root.rad0
        property vector4d rad1: root.rad1
        property vector4d rad2: root.rad2
        property vector4d rad3: root.rad3
        property vector4d rad4: root.rad4
        property vector4d rad5: root.rad5
        property vector4d rad6: root.rad6
        property vector4d rad7: root.rad7

        property vector4d def0: root.def0
        property vector4d def1: root.def1
        property vector4d def2: root.def2
        property vector4d def3: root.def3
        property vector4d def4: root.def4
        property vector4d def5: root.def5
        property vector4d def6: root.def6
        property vector4d def7: root.def7

        vertexShader: Qt.resolvedUrl("../shaders/blob.vert.qsb")
        fragmentShader: Qt.resolvedUrl("../shaders/blob.frag.qsb")
    }
}
