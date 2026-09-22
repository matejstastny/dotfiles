#version 440

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;
layout(location = 0) out vec2 qt_TexCoord0;

// only the two uniforms this stage actually reads. both stages share one buffer
// and each writes its members at the offsets its own block implies, so a member
// declared here at a different offset than blob.frag gives it lands on top of
// whatever the fragment block keeps there. leaving this a prefix of that block
// makes a collision impossible - never mirror the rest of it here
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
};

void main() {
    qt_TexCoord0 = qt_MultiTexCoord0;
    gl_Position = qt_Matrix * qt_Vertex;
}
