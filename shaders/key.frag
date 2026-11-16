// ClipForge background removal (colour key) — the preview side of
// `lib/models/chroma_key.dart`. Same maths as FFmpeg:
//   vf_chromakey.c: distance in BT.601 chroma (U,V), averaged over a 3x3
//                   neighbourhood, alpha = clamp((diff - similarity) / blend)
//   vf_despill.c:   default spill removal (mix 0.5, expand 0)
#version 460 core
#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 uSize;         // set by the engine
uniform vec4 uKey;          // key colour rgb (0..1), similarity
uniform vec4 uOpt;          // blend, despill (0 off, 1 green, 2 blue), sample step (px), unused
uniform sampler2D uTexture; // set by the engine: the filter input

out vec4 fragColor;

vec2 chromaUV(vec3 c) {
  return vec2(dot(c, vec3(-0.148223, -0.290993, 0.439216)),
              dot(c, vec3(0.439216, -0.367788, -0.071427)));
}

vec3 unpremul(vec4 s) {
  return s.a > 0.0 ? s.rgb / s.a : vec3(0.0);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec4 src = texture(uTexture, uv);
  vec3 c = unpremul(src);
  vec2 k = chromaUV(uKey.rgb);
  vec2 px = vec2(uOpt.z) / uSize;

  float diff = 0.0;
  for (int dy = -1; dy <= 1; dy++) {
    for (int dx = -1; dx <= 1; dx++) {
      vec3 s = unpremul(texture(uTexture, uv + vec2(float(dx), float(dy)) * px));
      diff += length(chromaUV(s) - k) * 0.70710678;
    }
  }
  diff /= 9.0;

  float a = uOpt.x > 0.0001 ? clamp((diff - uKey.a) / uOpt.x, 0.0, 1.0) : step(uKey.a, diff);

  if (uOpt.y > 0.5 && uOpt.y < 1.5) {
    c.g -= max(c.g - 0.5 * (c.r + c.b), 0.0);
  } else if (uOpt.y > 1.5) {
    c.b -= max(c.b - 0.5 * (c.r + c.g), 0.0);
  }

  a *= src.a;
  fragColor = vec4(c * a, a);
}
