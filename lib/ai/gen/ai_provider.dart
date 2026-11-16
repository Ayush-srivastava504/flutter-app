/// Bring-your-own-key AI generation: which services can make images and
/// videos, and the defaults ClipForge uses for them.
///
/// Calls go **straight from the phone to the provider** with the user's own
/// key — ClipForge has no server. Model ids change often, so every default
/// can be overridden in Settings → AI keys.
///
/// Checked against the providers' docs on 2026-11-13:
///  * OpenAI: `POST /v1/images/generations` (gpt-image models, base64
///    `data[0].b64_json`). The Sora video API was shut down 2026-09-24, so
///    OpenAI is images only.
///  * Gemini: `POST /v1beta/interactions` with `response_format`
///    `{type: image|video, aspect_ratio, duration}`; the result is base64
///    in `steps[type=model_output].content[type=image|video].data`.
///    Imagen and the Veo previews are shut down.
///  * Replicate: `POST /v1/models/{owner}/{name}/predictions` with
///    `Prefer: wait`, then poll `urls.get`; `output` is a URL (or list).
library ai_provider;

enum GenKind { image, video }

enum AiProvider {
  openai(
    'OpenAI',
    'sk-…',
    'platform.openai.com/api-keys',
    defaultImageModel: 'gpt-image-1',
    defaultVideoModel: null,
  ),
  gemini(
    'Google Gemini',
    'AIza…',
    'aistudio.google.com/apikey',
    defaultImageModel: 'gemini-nano-banana-2.1',
    defaultVideoModel: 'gemini-omni-1.2-flash',
  ),
  replicate(
    'Replicate',
    'r8_…',
    'replicate.com/account/api-tokens',
    defaultImageModel: 'black-forest-labs/flux-1.1-pro',
    defaultVideoModel: 'vidu/q3-turbo',
  );

  final String label;
  final String keyHint;
  final String keyUrl;
  final String defaultImageModel;

  /// Null when the provider can't make videos.
  final String? defaultVideoModel;

  const AiProvider(this.label, this.keyHint, this.keyUrl,
      {required this.defaultImageModel, required this.defaultVideoModel});

  bool supports(GenKind kind) => kind == GenKind.image || defaultVideoModel != null;

  String? defaultModel(GenKind kind) => kind == GenKind.image ? defaultImageModel : defaultVideoModel;

  static AiProvider? fromName(String? name) {
    for (final p in values) {
      if (p.name == name) return p;
    }
    return null;
  }
}

/// What to make. [aspect] is width / height of the project's frame.
class GenRequest {
  final String prompt;
  final GenKind kind;
  final double aspect;

  /// Video length in seconds (ignored for images).
  final int durationSec;

  const GenRequest({required this.prompt, required this.kind, required this.aspect, this.durationSec = 5});
}

/// The finished file's bytes and type.
class GeneratedMedia {
  final List<int> bytes;
  final String mimeType;
  const GeneratedMedia(this.bytes, this.mimeType);

  String get extension => switch (mimeType) {
        'image/png' => 'png',
        'image/jpeg' || 'image/jpg' => 'jpg',
        'image/webp' => 'webp',
        'video/quicktime' => 'mov',
        'video/webm' => 'webm',
        _ => mimeType.startsWith('video/') ? 'mp4' : 'png',
      };
}

/// A failure the user can act on: [message] is shown as-is.
class GenerationException implements Exception {
  final String message;
  const GenerationException(this.message);
  @override
  String toString() => message;
}

/// Picks the entry of [options] ("W:H") closest to [aspect].
String nearestRatio(double aspect, List<String> options) {
  String best = options.first;
  var bestDiff = double.infinity;
  for (final o in options) {
    final parts = o.split(':');
    final v = double.parse(parts[0]) / double.parse(parts[1]);
    final diff = (v - aspect).abs();
    if (diff < bestDiff) {
      bestDiff = diff;
      best = o;
    }
  }
  return best;
}
