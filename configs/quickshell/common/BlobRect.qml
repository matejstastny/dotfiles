import QtQuick
import "../"

Item {
    id: root

    readonly property Theme theme: Theme {}

    default property alias content: holder.data

    property real radius: 0
    property real topLeftRadius: -1
    property real topRightRadius: -1
    property real bottomLeftRadius: -1
    property real bottomRightRadius: -1

    // static shapes skip the spring entirely and never keep the group's frame
    // loop alive - the bar slab itself is the only one that wants this
    property bool blobStatic: false
    property real stiffness: theme.blobStiffness
    property real damping: theme.blobDamping
    property real deformScale: theme.blobDeformScale

    // symmetric 2x2 deformation, identity at rest
    property real m00: 1
    property real m01: 0
    property real m11: 1

    property real v00: 0
    property real v01: 0
    property real v11: 0

    property real prevX: 0
    property real prevY: 0
    property bool tracking: false

    readonly property real maxRadius: Math.min(width, height) / 2

    // shader corner order is top-right, bottom-right, bottom-left, top-left
    readonly property vector4d packedRadii: Qt.vector4d(Math.min(topRightRadius < 0 ? radius : topRightRadius, maxRadius), Math.min(bottomRightRadius < 0 ? radius : bottomRightRadius, maxRadius), Math.min(bottomLeftRadius < 0 ? radius : bottomLeftRadius, maxRadius), Math.min(topLeftRadius < 0 ? radius : topLeftRadius, maxRadius))

    // the shader undeforms each pixel before measuring, so it wants the inverse.
    // w carries the deform's smaller eigenvalue, which rescales the result back
    // into something the blend can treat as a distance
    readonly property vector4d packedDeform: {
        const det = m00 * m11 - m01 * m01;
        if (Math.abs(det) < 1e-6)
            return Qt.vector4d(1, 0, 1, 1);
        const halfTrace = (m00 + m11) / 2;
        const halfDiff = (m00 - m11) / 2;
        const minEigen = halfTrace - Math.sqrt(halfDiff * halfDiff + m01 * m01);
        return Qt.vector4d(m11 / det, -m01 / det, m00 / det, minEigen);
    }

    readonly property matrix4x4 deformMatrix: {
        const cx = width / 2;
        const cy = height / 2;
        return Qt.matrix4x4(m00, m01, 0, cx - m00 * cx - m01 * cy, m01, m11, 0, cy - m01 * cx - m11 * cy, 0, 0, 1, 0, 0, 0, 0, 1);
    }

    onVisibleChanged: if (!visible)
        reset()

    function reset(): void {
        m00 = 1;
        m01 = 0;
        m11 = 1;
        v00 = 0;
        v01 = 0;
        v11 = 0;
        tracking = false;
    }

    function step(dt: real, cx: real, cy: real): void {
        if (blobStatic)
            return;

        if (!tracking) {
            prevX = cx;
            prevY = cy;
            tracking = true;
            return;
        }

        // a stalled or absurdly long frame would read as a huge fake velocity
        if (dt > 0.1 || dt < 0.001) {
            prevX = cx;
            prevY = cy;
            return;
        }

        const vx = (cx - prevX) / dt;
        const vy = (cy - prevY) / dt;
        prevX = cx;
        prevY = cy;

        const speed = Math.sqrt(vx * vx + vy * vy);

        // stretch along the direction of travel, compress across it, keeping
        // area roughly constant - R(t) * diag(s, 1/s) * R(t) transpose
        let t00 = 1;
        let t01 = 0;
        let t11 = 1;
        if (speed > 5) {
            const stretch = 1 + Math.min(speed * deformScale, 0.35);
            const compress = 1 / stretch;
            const cosA = vx / speed;
            const sinA = vy / speed;
            t00 = stretch * cosA * cosA + compress * sinA * sinA;
            t01 = (stretch - compress) * cosA * sinA;
            t11 = stretch * sinA * sinA + compress * cosA * cosA;
        }

        // damping is solved implicitly: an explicit -c*v*dt term flips sign once
        // damping * dt passes 1 (around a 60ms frame here) and pumps the spring
        // instead of bleeding it
        const invDamp = 1 / (1 + damping * dt);

        v00 = (v00 - stiffness * (m00 - t00) * dt) * invDamp;
        m00 += v00 * dt;
        v01 = (v01 - stiffness * (m01 - t01) * dt) * invDamp;
        m01 += v01 * dt;
        v11 = (v11 - stiffness * (m11 - t11) * dt) * invDamp;
        m11 += v11 * dt;

        const offset = Math.abs(m00 - 1) + Math.abs(m01) + Math.abs(m11 - 1);
        const motion = Math.abs(v00) + Math.abs(v01) + Math.abs(v11);
        if (offset < 0.004 && motion < 0.05) {
            m00 = 1;
            m01 = 0;
            m11 = 1;
            v00 = 0;
            v01 = 0;
            v11 = 0;
        }
    }

    Item {
        id: holder

        anchors.fill: parent
        transform: Matrix4x4 {
            matrix: root.deformMatrix
        }
    }
}
