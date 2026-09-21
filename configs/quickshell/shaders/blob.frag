#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float smoothing;
    float borderWidth;
    float frameEnabled;
    float frameRadius;
    float ownerIndex;
    vec4 fillColor;
    vec4 borderColor;
    vec4 frameOuter;
    vec4 frameInner;
    vec4 quad;
    vec4 box0;
    vec4 box1;
    vec4 box2;
    vec4 box3;
    vec4 box4;
    vec4 box5;
    vec4 box6;
    vec4 box7;
    vec4 rad0;
    vec4 rad1;
    vec4 rad2;
    vec4 rad3;
    vec4 rad4;
    vec4 rad5;
    vec4 rad6;
    vec4 rad7;
    vec4 def0;
    vec4 def1;
    vec4 def2;
    vec4 def3;
    vec4 def4;
    vec4 def5;
    vec4 def6;
    vec4 def7;
};

const int SLOTS = 8;
const float FAR = 1e9;

// how deep a circular smin closes a gap at a == b, as a fraction of k
const float BLEND_DEPTH = 0.41421356;

// r = (topRight, bottomRight, bottomLeft, topLeft)
float sdRoundedBox(vec2 p, vec2 center, vec2 halfSize, vec4 r) {
    p -= center;
    r.xy = (p.x > 0.0) ? r.xy : r.wz;
    r.x = (p.y > 0.0) ? r.y : r.x;
    vec2 q = abs(p) - halfSize + r.x;
    return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - r.x;
}

float sdRoundedBox(vec2 p, vec2 center, vec2 halfSize, float r) {
    vec2 q = abs(p - center) - halfSize + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - r;
}

float sdBox(vec2 p, vec2 center, vec2 halfSize) {
    vec2 q = abs(p - center) - halfSize;
    return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0)));
}

// circular smooth min: the fillet between two surfaces is a true arc of radius k,
// and it deviates from min() only where *both* distances are under k. the usual
// polynomial smin instead deviates across the whole band |a - b| < k, which eats
// into both shapes everywhere and reads as deflated rather than fused
float smin(float a, float b, float k) {
    return max(k, min(a, b)) - length(max(vec2(k) - vec2(a, b), vec2(0.0)));
}

// dual of smin, except a's zero crossing stays sharp. the frame's outer edge is
// the one surface in the field that has to stay square: it runs off-screen, and
// a fillet there would pull it inwards and leave a notch at each screen corner
float smaxSharpA(float a, float b, float k) {
    float hard = max(a, b);
    float soft = min(-k, hard) + length(max(vec2(a, b) + vec2(k), vec2(0.0)));
    return hard + (soft - hard) * smoothstep(0.0, k * 0.5, -a);
}

void main() {
    // this node only covers a sub-rect of the field, so rebuild the group-space
    // position from its own uv rather than assuming it spans the whole surface
    vec2 p = quad.xy + qt_TexCoord0 * quad.zw;

    vec4 boxes[SLOTS] = vec4[SLOTS](box0, box1, box2, box3, box4, box5, box6, box7);
    vec4 radii[SLOTS] = vec4[SLOTS](rad0, rad1, rad2, rad3, rad4, rad5, rad6, rad7);
    vec4 defs[SLOTS] = vec4[SLOTS](def0, def1, def2, def3, def4, def5, def6, def7);

    float innerTop = frameInner.y - frameInner.w;
    float innerBottom = frameInner.y + frameInner.w;
    float innerLeft = frameInner.x - frameInner.z;
    float innerRight = frameInner.x + frameInner.z;

    float dist[SLOTS];
    for (int i = 0; i < SLOTS; i++) {
        vec2 center = boxes[i].xy;
        vec2 halfSize = boxes[i].zw;
        vec2 reach = halfSize * 1.4 + vec2(smoothing * 1.5);

        if (halfSize.x <= 0.0 || halfSize.y <= 0.0 || abs(p.x - center.x) > reach.x || abs(p.y - center.y) > reach.y) {
            dist[i] = FAR;
            continue;
        }

        // evaluating the box in its own un-deformed frame is what squashes it; the
        // result is no longer a true distance, so scale by the deform's smaller
        // eigenvalue to get a conservative one back
        mat2 undeform = mat2(defs[i].x, defs[i].y, defs[i].y, defs[i].z);
        vec2 local = center + undeform * (p - center);
        float d = sdRoundedBox(local, center, halfSize, radii[i]) * max(defs[i].w, 0.01);

        // a drawer parked in the frame band still blends with it, and smin deviates
        // from min even where one side sits well inside the other - along a whole
        // buried edge that reads as the band swelling. scaling the field on the axis
        // that faces the band narrows the blend in that direction only; lowering
        // `smoothing` instead would square off every other junction in the group
        if (frameEnabled > 0.5) {
            // 0 = clear of the band, 1 = the buried edge is right on its inner wall
            float yProx = 1.0 - min(smoothstep(0.0, smoothing, (center.y + halfSize.y) - innerTop), smoothstep(0.0, smoothing, innerBottom - (center.y - halfSize.y)));
            float xProx = 1.0 - min(smoothstep(0.0, smoothing, (center.x + halfSize.x) - innerLeft), smoothstep(0.0, smoothing, innerRight - (center.x - halfSize.x)));

            // which axis this pixel leaves the box by: the gradient direction out in
            // the corner region, the nearer face once level with or inside it
            vec2 q = abs(p - center) - halfSize;
            vec2 outside = max(q, vec2(0.0));
            float span = max(length(outside), 0.001);
            float faceY = smoothstep(-4.0, 4.0, q.y - q.x);
            float corner = smoothstep(0.0, 2.0, length(outside));
            float xWeight = mix(1.0 - faceY, outside.x / span, corner);
            float yWeight = mix(faceY, outside.y / span, corner);

            d *= 1.0 + (xProx * xWeight + yProx * yWeight) * 3.0;
        }

        dist[i] = d;
    }

    // every node evaluates the whole field but paints only the pixels its own
    // shape is nearest to. that is what lets the nodes overlap: each pixel is
    // written exactly once, so the antialiased edges never blend over themselves
    float owner = -2.0;
    float nearest = FAR;
    for (int i = 0; i < SLOTS; i++) {
        if (dist[i] < smoothing && dist[i] < nearest) {
            nearest = dist[i];
            owner = float(i);
        }
    }

    float merged = FAR;
    for (int i = 0; i < SLOTS; i++)
        merged = min(merged, dist[i]);

    // pairwise, because smin(a, b) <= min(a, b): taking the min over every pair
    // gives the same field as folding them in sequence, without the fold order
    // biasing which shapes get to blend
    for (int i = 0; i < SLOTS; i++) {
        if (dist[i] >= smoothing)
            continue;
        for (int j = i + 1; j < SLOTS; j++) {
            if (dist[j] >= smoothing)
                continue;
            merged = min(merged, smin(dist[i], dist[j], smoothing));
        }
    }

    // the frame is the surface everything else hangs off: a drawer parked behind it
    // shares its skin, so opening one reads as the outline being drawn inwards
    // rather than a card sliding over the top of it
    if (frameEnabled > 0.5) {
        float outerTop = frameOuter.y - frameOuter.w;
        float outerBottom = frameOuter.y + frameOuter.w;
        float outerLeft = frameOuter.x - frameOuter.z;
        float outerRight = frameOuter.x + frameOuter.z;

        // a retracted drawer is still smin'd with the band and would push a bulge
        // into the screen, so the inner wall recedes by however deep the drawer is
        // buried and the junction stays flat. the wall only starts giving once the
        // drawer is in past the depth the blend closes on its own - yield sooner
        // and it outruns the junction, denting the inner edge instead
        float onset = smoothing * BLEND_DEPTH * 0.5;
        float sink = 0.0;
        for (int i = 0; i < SLOTS; i++) {
            vec2 center = boxes[i].xy;
            vec2 halfSize = boxes[i].zw;
            if (halfSize.x <= 0.0 || halfSize.y <= 0.0)
                continue;

            // each side tracks the drawer's far edge, capped at the band's thickness
            float topPen = clamp(innerTop - (center.y + halfSize.y) - onset, 0.0, innerTop - outerTop);
            float bottomPen = clamp((center.y - halfSize.y) - innerBottom - onset, 0.0, outerBottom - innerBottom);
            float leftPen = clamp(innerLeft - (center.x + halfSize.x) - onset, 0.0, innerLeft - outerLeft);
            float rightPen = clamp((center.x - halfSize.x) - innerRight - onset, 0.0, outerRight - innerRight);

            // the pocket is only as wide as the drawer, and only as deep as the band
            float alongX = smoothstep(smoothing * 2.0, 0.0, max(abs(p.x - center.x) - halfSize.x, 0.0));
            float alongY = smoothstep(smoothing * 2.0, 0.0, max(abs(p.y - center.y) - halfSize.y, 0.0));
            float topZone = 1.0 - smoothstep(innerTop, innerTop + smoothing, p.y);
            float bottomZone = smoothstep(innerBottom - smoothing, innerBottom, p.y);
            float leftZone = 1.0 - smoothstep(innerLeft, innerLeft + smoothing, p.x);
            float rightZone = smoothstep(innerRight - smoothing, innerRight, p.x);

            sink = max(sink, max(max(topPen * alongX * topZone, bottomPen * alongX * bottomZone), max(leftPen * alongY * leftZone, rightPen * alongY * rightZone)));
        }

        float outer = sdBox(p, frameOuter.xy, frameOuter.zw) - 1.0;
        float inner = sdRoundedBox(p, frameInner.xy, frameInner.zw, frameRadius) - sink;

        // a fillet wider than the band cannot finish inside it, and the square outer
        // term bleeds through and bulges the inner corners. the default band is
        // thinner than the blend radius, so clamp to the narrowest side - every
        // inner corner is bounded by its thinner neighbour, so the global min holds
        float thinnest = min(min(innerTop - outerTop, outerBottom - innerBottom), min(innerLeft - outerLeft, outerRight - innerRight));
        float k = clamp(min(smoothing, thinnest - 1.0), 1.0, smoothing);

        // smin is monotone in each argument, so folding the frame in once here is
        // the same field as sminning it against every box separately
        float dFrame = smaxSharpA(outer, -inner, k);
        if (dFrame < smoothing && dFrame < nearest) {
            nearest = dFrame;
            owner = -1.0;
        }
        merged = smin(merged, dFrame, smoothing);
    }

    // the frame is split across four edge bands that tile the ring without
    // overlapping, so they all share owner -1 and still never double up
    if (abs(owner - ownerIndex) > 0.5)
        discard;

    float fw = max(fwidth(merged), 0.001);

    // everything past the blend radius is fully transparent anyway, and bailing
    // keeps the far-field sentinel out of the coverage maths
    if (merged > smoothing)
        discard;

    float outerCoverage = 1.0 - smoothstep(-fw, fw, merged);
    float innerCoverage = 1.0 - smoothstep(-fw, fw, merged + borderWidth);

    fragColor = mix(borderColor, fillColor, innerCoverage) * outerCoverage * qt_Opacity;
}
