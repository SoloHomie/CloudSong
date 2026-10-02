// 推荐页 3D 粒子背景片元着色器 (ParticleBackdrop 使用, 2026-10-02)
// 100 粒子 4 层深度循环漂移 + 闪烁; 近大远小透视即"3D"感
// Qt 6 Vulkan 语义: 非采样器 uniform 必须放 std140 binding=0 块 (qt_Matrix/qt_Opacity 打头);
// #version 必须写进源文件 (qsb 的 SPIR-V 烘焙按源内版本走, 无版本号会当 ES100 报错)
#version 440

layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float uTime;
    float uW;
    float uH;
    vec4 uAccent;
    float uAlpha;
};

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main() {
    vec2 uv = gl_FragCoord.xy / vec2(uW, uH);
    vec3 col = vec3(0.0);
    float a = 0.0;
    for (int j = 0; j < 25; j++) {
        for (int i = 0; i < 4; i++) {
            vec2 cell = vec2(float(i), float(j));
            float h1 = hash(cell);
            float h2 = hash(cell + 5.13);
            float h3 = hash(cell + 9.71);
            float speed = 0.015 + 0.08 * h3;
            float z = fract(h3 * 7.0 + uTime * speed);
            vec2 sp = vec2(0.5) + (vec2(h1, h2) - 0.5) / max(z, 0.15);
            vec2 d = uv - sp;
            float dist2 = dot(d, d);
            if (dist2 > 0.0016) continue;
            float sz = 0.0009 / max(z, 0.15);
            float tw = 0.55 + 0.45 * sin(uTime * (1.0 + h2 * 3.0) + h1 * 6.283);
            float m = exp(-dist2 / (sz * sz * 0.55));
            col += mix(uAccent.rgb, vec3(1.0), 0.35 + 0.4 * h3) * m * tw;
            a += m * tw * 0.8;
        }
    }
    fragColor = vec4(col, min(a, 1.0) * uAlpha);
}
