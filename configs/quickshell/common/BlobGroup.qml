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

        return Qt.vector4d(Math.max(base.x * factors[0], 2), Math.max(base.y * factors[1], 2), Math.max(base.z * factors[2], 2), Math.max(base.w * factors[3], 2));
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

        for (let i = 0; i < slotCount; i++) {
            const box = boxes[i];
            if (!box) {
                field["box" + i] = Qt.vector4d(0, 0, 0, 0);
                continue;
            }
            field["box" + i] = Qt.vector4d(box.cx, box.cy, box.hw, box.hh);
            field["rad" + i] = cornerRadii(boxes, i);
            field["def" + i] = box.shape.packedDeform;
        }
    }

    ShaderEffect {
        id: field

        anchors.fill: parent

        property size size: Qt.size(width, height)
        property real smoothing: root.smoothing
        property real borderWidth: root.borderWidth
        property color fillColor: root.color
        property color borderColor: root.borderColor

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

        vertexShader: Qt.resolvedUrl("../shaders/blob.vert.qsb")
        fragmentShader: Qt.resolvedUrl("../shaders/blob.frag.qsb")
    }
}
