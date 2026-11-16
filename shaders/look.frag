// ClipForge look shader — the preview side of `lib/models/look_x.dart`.
// Steps, in the same order as the FFmpeg export (`lookFilters`):
//   colour matrix -> split tone -> negate -> pixelate -> posterize -> ink edges ->
//   sharpen -> chroma split -> grain -> vignette
// Pixel sizes (pixelate, chroma) arrive already scaled to this texture.
#version 460 core
#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 uSize;        // set by the engine (ImageFilter.shader)
uniform vec4 uRowR;        // colour matrix rows: r,g,b coefficients + offset (0..1)
uniform vec4 uRowG;
uniform vec4 uRowB;
uniform vec4 uFxA;         // negate mix, pixel size (px), posterize levels, posterize mix
uniform vec4 uFxB;         // edges, sharpen, chroma (px), grain
uniform vec4 uFxC;         // vignette, seed, unused, unused
uniform vec4 uShadows;     // split tone: rgb push for shadows (-1..1)
uniform vec4 uHighlights;  // split tone: rgb push for highlights (-1..1)
uniform sampler2D uTexture; // set by the engine: the filter input

out vec4 fragColor;

vec3 matrixColor(vec3 c) {
  return clamp(vec3(
    dot(uRowR.rgb, c) + uRowR.a,
    dot(uRowG.rgb, c) + uRowG.a,
    dot(uRowB.rgb, c) + uRowB.a), 0.0, 1.0);
}

// FFmpeg colorbalance (vf_colorbalance.c get_component), so the preview
// tints shadows/highlights the same way the export does.
float balance(float v, float l, float sh, float hi) {
  const float a = 4.0;
  const float b = 0.333;
  const float scale = 0.7;
  sh *= clamp((b - l) * a + 0.5, 0.0, 1.0) * scale;
  hi *= clamp((l + b - 1.0) * a + 0.5, 0.0, 1.0) * scale;
  return clamp(v + sh + hi, 0.0, 1.0);
}

vec3 splitTone(vec3 c) {
  float l = (max(c.r, max(c.g, c.b)) + min(c.r, min(c.g, c.b))) * 0.5;
  return vec3(
    balance(c.r, l, uShadows.r, uHighlights.r),
    balance(c.g, l, uShadows.g, uHighlights.g),
    balance(c.b, l, uShadows.b, uHighlights.b));
}

vec2 snapUv(vec2 uv) {
  float p = uFxA.y;
  if (p < 1.5) return uv;
  vec2 cell = vec2(p) / uSize;
  return (floor(uv / cell) + 0.5) * cell;
}

// Colour after the per-pixel steps (matrix, negate, posterize) at uv.
vec3 base(vec2 uv) {
  vec3 c = splitTone(matrixColor(texture(uTexture, snapUv(uv)).rgb));
  c = mix(c, 1.0 - c, uFxA.x);
  float levels = uFxA.z;
  if (levels >= 2.0) {
    vec3 q = floor(c * (levels - 1.0) + 0.5) / (levels - 1.0);
    c = mix(c, q, uFxA.w);
  }
  return c;
}

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

void main() {
  vec2 pos = FlutterFragCoord().xy;
#ifdef IMPELLER_TARGET_OPENGLES
  pos.y = uSize.y - pos.y;
#endif
  vec2 uv = pos / uSize;
  vec2 texel = 1.0 / uSize;

  vec3 c = base(uv);

  // Ink edges (Sobel on luma) and sharpen (unsharp vs 3x3 box) share taps.
  float edges = uFxB.x;
  float sharpen = uFxB.y;
  if (edges > 0.0 || sharpen > 0.0) {
    vec3 tl = base(uv + texel * vec2(-1.0, -1.0));
    vec3 t  = base(uv + texel * vec2( 0.0, -1.0));
    vec3 tr = base(uv + texel * vec2( 1.0, -1.0));
    vec3 l  = base(uv + texel * vec2(-1.0,  0.0));
    vec3 r  = base(uv + texel * vec2( 1.0,  0.0));
    vec3 bl = base(uv + texel * vec2(-1.0,  1.0));
    vec3 b  = base(uv + texel * vec2( 0.0,  1.0));
    vec3 br = base(uv + texel * vec2( 1.0,  1.0));
    if (sharpen > 0.0) {
      vec3 blur = (tl + t + tr + l + c + r + bl + b + br) / 9.0;
      c = clamp(c + (c - blur) * sharpen * 1.5, 0.0, 1.0);
    }
    if (edges > 0.0) {
      float gx = -luma(tl) - 2.0 * luma(l) - luma(bl) + luma(tr) + 2.0 * luma(r) + luma(br);
      float gy = -luma(tl) - 2.0 * luma(t) - luma(tr) + luma(bl) + 2.0 * luma(b) + luma(br);
      float e = smoothstep(0.25, 0.6, length(vec2(gx, gy)));
      c *= 1.0 - edges * e;
    }
  }

  // Chroma split: red pulled left, blue pushed right.
  float shift = uFxB.z;
  if (shift > 0.0) {
    vec2 d = vec2(shift * texel.x, 0.0);
    c.r = base(uv - d).r;
    c.b = base(uv + d).b;
  }

  // Grain: luma noise, ±(grain * 30 / 255) like FFmpeg's noise=c0s.
  float grain = uFxB.w;
  if (grain > 0.0) {
    float n = hash(pos + uFxC.y) - 0.5;
    c = clamp(c + n * grain * (60.0 / 255.0), 0.0, 1.0);
  }

  // Vignette: darken toward the corners.
  float vig = uFxC.x;
  if (vig > 0.0) {
    vec2 d = uv - 0.5;
    float r2 = dot(d, d) * 2.0; // 0 at centre, 1 at the corners
    c *= 1.0 - vig * smoothstep(0.15, 1.0, r2);
  }

  float a = texture(uTexture, uv).a;
  fragColor = vec4(c * a, a);
}
