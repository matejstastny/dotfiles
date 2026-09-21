#version 440

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;
layout(location = 0) out vec2 qt_TexCoord0;

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

void main() {
    qt_TexCoord0 = qt_MultiTexCoord0;
    gl_Position = qt_Matrix * qt_Vertex;
}
