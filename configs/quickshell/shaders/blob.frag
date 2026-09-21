#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;
    float smoothing;
    float borderWidth;
    vec4 fillColor;
    vec4 borderColor;
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

// r = (topRight, bottomRight, bottomLeft, topLeft)
float sdRoundedBox(vec2 p, vec2 center, vec2 halfSize, vec4 r) {
    p -= center;
    r.xy = (p.x > 0.0) ? r.xy : r.wz;
    r.x = (p.y > 0.0) ? r.y : r.x;
    vec2 q = abs(p) - halfSize + r.x;
    return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - r.x;
}

// circular smooth min: the fillet between two surfaces is a true arc of radius k,
// and it deviates from min() only where *both* distances are under k. the usual
// polynomial smin instead deviates across the whole band |a - b| < k, which eats
// into both shapes everywhere and reads as deflated rather than fused
float smin(float a, float b, float k) {
    return max(k, min(a, b)) - length(max(vec2(k) - vec2(a, b), vec2(0.0)));
}

void main() {
    vec2 p = qt_TexCoord0 * size;

    vec4 boxes[SLOTS] = vec4[SLOTS](box0, box1, box2, box3, box4, box5, box6, box7);
    vec4 radii[SLOTS] = vec4[SLOTS](rad0, rad1, rad2, rad3, rad4, rad5, rad6, rad7);
    vec4 defs[SLOTS] = vec4[SLOTS](def0, def1, def2, def3, def4, def5, def6, def7);

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
        dist[i] = sdRoundedBox(local, center, halfSize, radii[i]) * max(defs[i].w, 0.01);
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

    float fw = max(fwidth(merged), 0.001);

    // everything past the blend radius is fully transparent anyway, and bailing
    // keeps the far-field sentinel out of the coverage maths
    if (merged > smoothing)
        discard;

    float outer = 1.0 - smoothstep(-fw, fw, merged);
    float inner = 1.0 - smoothstep(-fw, fw, merged + borderWidth);

    fragColor = mix(borderColor, fillColor, inner) * outer * qt_Opacity;
}
