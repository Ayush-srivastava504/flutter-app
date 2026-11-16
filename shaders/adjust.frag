// ClipForge "Tune" shader — the photo editor's adjust step
// (`lib/photo/photo_edit.dart` adjustParams). Runs for the on-screen preview
// and, unchanged, for the full-resolution export, so they match exactly.
// Order: exposure -> white balance -> black/white point -> shadows/highlights
// -> contrast -> brightness -> clarity/sharpen -> saturation/vibrance ->
// fade -> grain -> vignette.
#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;        // set by the engine (ImageFilter.shader)
uniform vec4 uA;           // exposure, brightness, contrast, saturation   (-1..1)
uniform vec4 uB;           // highlights, shadows, whites, blacks          (-1..1)
uniform vec4 uC;           // vibrance, warmth, tint (-1..1), fade (0..1)
uniform vec4 uD;           // clarity (-1..1), sharpen, vignette, grain (0..1)
uniform vec4 uE;           // pixel scale (texture px per 1080 px), seed, -, -
uniform sampler2D uTexture; // set by the engine: the filter input

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

// Per-pixel tone/colour steps that don't need neighbours.
vec3 tone(vec3 c) {
  // Exposure: ±2 stops.
  c *= exp2(uA.x * 2.0);

  // White balance: warmth moves red/blue apart, tint moves green/magenta.
  c *= vec3(1.0 + uC.y * 0.18, 1.0 - uC.z * 0.12, 1.0 - uC.y * 0.18);

  // Black / white points (levels).
  float bp = -uB.w * 0.12;
  float wp = 1.0 - uB.z * 0.12;
  c = (c - bp) / max(wp - bp, 0.05);

  // Shadows / highlights: lift or pull each tonal range, preserving hue.
  float l = clamp(luma(c), 0.0, 1.0);
  float sm = 1.0 - smoothstep(0.0, 0.55, l);
  float hm = smoothstep(0.45, 1.0, l);
  float target = l + uB.y * 0.35 * sm + uB.x * 0.35 * hm;
  c *= (l > 0.001) ? max(target, 0.0) / l : 1.0;

  // Contrast around mid grey.
  c = (c - 0.5) * (1.0 + uA.z) + 0.5;

  // Brightness: midtone gamma, keeps black and white fixed.
  c = clamp(c, 0.0, 1.0);
  c = pow(c, vec3(exp2(-uA.y)));
  return c;
}

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
  vec4 src = texture(uTexture, uv);
  vec3 c = tone(src.rgb);

  // Clarity (local contrast, wide radius) and sharpen (fine detail).
  float clarity = uD.x;
  float sharpen = uD.y;
  if (clarity != 0.0 || sharpen > 0.0) {
    float r = max(uE.x * 12.0, 2.0); // clarity radius, ~12 px at 1080 wide
    vec3 wide = vec3(0.0);
    for (int i = 0; i < 8; i++) {
      float ang = float(i) * 0.785398;
      wide += tone(texture(uTexture, uv + texel * r * vec2(cos(ang), sin(ang))).rgb);
    }
    wide /= 8.0;
    if (clarity != 0.0) {
      // Weight to midtones so skies and shadows don't halo.
      float l = luma(c);
      float mid = 1.0 - abs(l - 0.5) * 2.0;
      c += (c - wide) * clarity * 1.2 * mid;
    }
    if (sharpen > 0.0) {
      vec3 near = (tone(texture(uTexture, uv + vec2(texel.x, 0.0)).rgb) +
                   tone(texture(uTexture, uv - vec2(texel.x, 0.0)).rgb) +
                   tone(texture(uTexture, uv + vec2(0.0, texel.y)).rgb) +
                   tone(texture(uTexture, uv - vec2(0.0, texel.y)).rgb)) * 0.25;
      c += (c - near) * sharpen * 2.0;
    }
  }
  c = clamp(c, 0.0, 1.0);

  // Saturation, then vibrance (boosts muted colours more than vivid ones).
  float g = luma(c);
  c = mix(vec3(g), c, 1.0 + uA.w);
  float sat = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b));
  c = mix(vec3(g), c, 1.0 + uC.x * (1.0 - sat));

  // Fade: lift the blacks and soften the whites, like matte film.
  c = mix(c, 0.12 + c * 0.82, uC.w);

  // Grain.
  if (uD.w > 0.0) {
    float n = hash(floor(pos / max(uE.x, 1.0)) + uE.y) - 0.5;
    c += n * uD.w * 0.16;
  }

  // Vignette.
  if (uD.z > 0.0) {
    vec2 d = uv - 0.5;
    c *= 1.0 - uD.z * smoothstep(0.15, 1.0, dot(d, d) * 2.0);
  }

  c = clamp(c, 0.0, 1.0);
  fragColor = vec4(c * src.a, src.a);
}
