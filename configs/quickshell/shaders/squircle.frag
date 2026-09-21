#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;
    vec4 fillColor;
    vec4 borderColor;
    float radius;
    float smoothing;
    float borderWidth;
};

// superellipse (squircle) distance to a rounded box - blends the corner
// exponent between 2 (circular arc) and 8 (continuous "iOS-style" corner)
float squircleDist(vec2 p, vec2 halfSize, float r, float n) {
    vec2 q = abs(p) - (halfSize - r);
    vec2 qc = max(q, 0.0);
    float outside = pow(pow(qc.x, n) + pow(qc.y, n), 1.0 / n) - r;
    float inside = min(max(q.x, q.y), 0.0);
    return outside + inside;
}

void main() {
    vec2 halfSize = size * 0.5;
    vec2 p = (qt_TexCoord0 - 0.5) * size;
    float n = mix(2.0, 8.0, clamp(smoothing, 0.0, 1.0));
    float r = min(radius, min(halfSize.x, halfSize.y));

    float d = squircleDist(p, halfSize, r, n);

    float aa = 1.0;
    float outerAlpha = 1.0 - smoothstep(-aa, aa, d);
    float fillAlpha = 1.0 - smoothstep(-aa, aa, d + borderWidth);

    vec4 result = mix(borderColor, fillColor, fillAlpha);
    fragColor = result * outerAlpha * qt_Opacity;
}
