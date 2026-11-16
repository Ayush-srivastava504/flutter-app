import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'ai_provider.dart';

/// One provider's image/video generation over HTTP. Request building and
/// response parsing are separate functions so they are unit-tested with a
/// mock client; [Generator.cancel] closes the client, which aborts any
/// request in flight.
abstract class Generator {
  final http.Client client;
  final String apiKey;
  final String model;
  bool _cancelled = false;

  Generator(this.client, this.apiKey, this.model);

  AiProvider get provider;

  Future<GeneratedMedia> generate(GenRequest r, {void Function(String status)? onStatus});

  void cancel() {
    _cancelled = true;
    client.close();
  }

  bool get cancelled => _cancelled;

  /// Runs [call], turning network/HTTP failures into readable messages.
  Future<http.Response> send(Future<http.Response> Function() call) async {
    if (_cancelled) throw const GenerationException('Cancelled.');
    try {
      final res = await call().timeout(const Duration(minutes: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) return res;
      throw GenerationException(httpErrorMessage(provider, res.statusCode, res.body));
    } on GenerationException {
      rethrow;
    } on SocketException {
      throw const GenerationException('No internet connection. Check Wi-Fi or mobile data and try again.');
    } on TimeoutException {
      throw GenerationException('${provider.label} took too long to answer. Try again in a minute.');
    } on http.ClientException catch (e) {
      if (_cancelled) throw const GenerationException('Cancelled.');
      throw GenerationException('Network error: ${e.message}');
    }
  }

  Future<GeneratedMedia> download(String url, String fallbackMime, {Map<String, String> headers = const {}}) async {
    final res = await send(() => client.get(Uri.parse(url), headers: headers));
    final type = res.headers['content-type']?.split(';').first.trim();
    return GeneratedMedia(res.bodyBytes, (type == null || type.isEmpty || type == 'application/octet-stream') ? fallbackMime : type);
  }
}

/// The provider's own error text when it sent one, plus what to do about
/// the common cases.
String httpErrorMessage(AiProvider p, int status, String body) {
  String? detail;
  try {
    final j = jsonDecode(body);
    if (j is Map) {
      final e = j['error'];
      detail = e is Map ? (e['message'] ?? e['status'])?.toString() : (e ?? j['detail'] ?? j['title'])?.toString();
    }
  } catch (_) {}
  final tail = detail == null || detail.isEmpty ? '' : ' ($detail)';
  return switch (status) {
    401 || 403 => '${p.label} rejected the API key$tail. Check it in Settings → AI keys.',
    402 || 429 => '${p.label} says you hit a rate limit or ran out of credit$tail.',
    404 => '${p.label} doesn\'t know that model$tail. Check the model name in Settings → AI keys.',
    >= 500 => '${p.label} is having trouble right now$tail. Try again later.',
    _ => '${p.label} couldn\'t do that$tail.',
  };
}

// ---- OpenAI ---------------------------------------------------------------

/// gpt-image sizes: portrait, landscape or square.
String openAiImageSize(double aspect) => aspect < 0.9
    ? '1024x1536'
    : aspect > 1.1
        ? '1536x1024'
        : '1024x1024';

Map<String, dynamic> openAiImageBody(String model, GenRequest r) =>
    {'model': model, 'prompt': r.prompt, 'size': openAiImageSize(r.aspect), 'n': 1};

class OpenAiGenerator extends Generator {
  OpenAiGenerator(super.client, super.apiKey, super.model);

  @override
  AiProvider get provider => AiProvider.openai;

  @override
  Future<GeneratedMedia> generate(GenRequest r, {void Function(String status)? onStatus}) async {
    if (r.kind == GenKind.video) {
      throw const GenerationException('OpenAI no longer offers video generation. Use Gemini or Replicate for videos.');
    }
    onStatus?.call('Painting your image…');
    final res = await send(() => client.post(
          Uri.parse('https://api.openai.com/v1/images/generations'),
          headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
          body: jsonEncode(openAiImageBody(model, r)),
        ));
    final data = (jsonDecode(res.body) as Map)['data'];
    final first = data is List && data.isNotEmpty ? data.first as Map : const {};
    final b64 = first['b64_json'] as String?;
    if (b64 != null) return GeneratedMedia(base64Decode(b64), 'image/png');
    final url = first['url'] as String?;
    if (url != null) return download(url, 'image/png');
    throw const GenerationException('OpenAI returned no image. Try a different prompt.');
  }
}

// ---- Google Gemini (Interactions API) -------------------------------------

const geminiImageRatios = ['1:1', '2:3', '3:2', '3:4', '4:3', '4:5', '5:4', '9:16', '16:9', '21:9'];

Map<String, dynamic> geminiBody(String model, GenRequest r) => {
      'model': model,
      'input': r.prompt,
      'response_format': r.kind == GenKind.image
          ? {'type': 'image', 'aspect_ratio': nearestRatio(r.aspect, geminiImageRatios)}
          : {
              'type': 'video',
              'aspect_ratio': r.aspect < 1 ? '9:16' : '16:9',
              'duration': '${r.durationSec.clamp(3, 15)}s',
            },
    };

/// The first image/video item in an interaction: `steps[].content[]` of a
/// `model_output` step (current schema) or the older `outputs[]`.
/// Returns (base64 data, uri, mime type).
(String?, String?, String?)? geminiMediaItem(Map<String, dynamic> j, GenKind kind) {
  final want = kind == GenKind.image ? 'image' : 'video';
  Iterable<Map> items() sync* {
    final steps = j['steps'];
    if (steps is List) {
      for (final s in steps.whereType<Map>()) {
        if (s['type'] != null && s['type'] != 'model_output') continue;
        final c = s['content'];
        if (c is List) yield* c.whereType<Map>();
      }
    }
    final outputs = j['outputs'];
    if (outputs is List) yield* outputs.whereType<Map>();
  }

  for (final it in items()) {
    if (it['type'] != want) continue;
    final data = it['data'] as String?;
    final uri = it['uri'] as String?;
    if (data == null && uri == null) continue;
    return (data, uri, (it['mime_type'] ?? it['mimeType']) as String?);
  }
  return null;
}

class GeminiGenerator extends Generator {
  GeminiGenerator(super.client, super.apiKey, super.model);

  static const _base = 'https://generativelanguage.googleapis.com/v1beta';

  @override
  AiProvider get provider => AiProvider.gemini;

  @override
  Future<GeneratedMedia> generate(GenRequest r, {void Function(String status)? onStatus}) async {
    onStatus?.call(r.kind == GenKind.image ? 'Painting your image…' : 'Filming your video — this can take a few minutes…');
    final res = await send(() => client.post(
          Uri.parse('$_base/interactions'),
          headers: {'x-goog-api-key': apiKey, 'Content-Type': 'application/json'},
          body: jsonEncode(geminiBody(model, r)),
        ));
    final item = geminiMediaItem(jsonDecode(res.body) as Map<String, dynamic>, r.kind);
    final fallback = r.kind == GenKind.image ? 'image/png' : 'video/mp4';
    if (item == null) {
      throw GenerationException('Gemini returned no ${r.kind.name}. It may have declined the prompt — try rewording it.');
    }
    final (data, uri, mime) = item;
    if (data != null) return GeneratedMedia(base64Decode(data), mime ?? fallback);
    // URI delivery: a Files API resource or a full URL.
    final url = uri!.startsWith('http') ? uri : '$_base/${uri.replaceFirst(RegExp('^/'), '')}:download?alt=media';
    return download(url, mime ?? fallback, headers: {'x-goog-api-key': apiKey});
  }
}

// ---- Replicate ------------------------------------------------------------

const replicateImageRatios = ['1:1', '16:9', '9:16', '4:5', '5:4', '3:4', '4:3', '2:3', '3:2'];

Map<String, dynamic> replicateBody(GenRequest r) => {
      'input': {
        'prompt': r.prompt,
        if (r.kind == GenKind.image) 'aspect_ratio': nearestRatio(r.aspect, replicateImageRatios),
        if (r.kind == GenKind.video) ...{
          'aspect_ratio': nearestRatio(r.aspect, const ['16:9', '9:16', '1:1']),
          'duration': r.durationSec,
        },
      },
    };

/// `output` is a URL, a list of URLs, or (rarely) a map with a url.
String? replicateOutputUrl(dynamic output) {
  if (output is String) return output;
  if (output is List) {
    for (final o in output) {
      final u = replicateOutputUrl(o);
      if (u != null) return u;
    }
  }
  if (output is Map) return (output['url'] ?? output['video'] ?? output['image']) as String?;
  return null;
}

class ReplicateGenerator extends Generator {
  /// How long to wait between status checks (shorter in tests).
  final Duration pollEvery;

  ReplicateGenerator(super.client, super.apiKey, super.model, {this.pollEvery = const Duration(seconds: 3)});

  @override
  AiProvider get provider => AiProvider.replicate;

  @override
  Future<GeneratedMedia> generate(GenRequest r, {void Function(String status)? onStatus}) async {
    final headers = {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'};
    onStatus?.call('Starting…');
    final res = await send(() => client.post(
          Uri.parse('https://api.replicate.com/v1/models/$model/predictions'),
          headers: {...headers, 'Prefer': 'wait=60'},
          body: jsonEncode(replicateBody(r)),
        ));
    var j = jsonDecode(res.body) as Map<String, dynamic>;
    final deadline = DateTime.now().add(const Duration(minutes: 15));
    while (true) {
      final status = j['status'] as String?;
      if (status == 'succeeded') break;
      if (status == 'failed' || status == 'canceled') {
        final err = j['error']?.toString();
        throw GenerationException('Replicate couldn\'t make it${err == null || err.isEmpty ? '' : ': $err'}.');
      }
      if (DateTime.now().isAfter(deadline)) {
        throw const GenerationException('Replicate is taking too long. Check your dashboard there and try again.');
      }
      onStatus?.call(status == 'processing'
          ? (r.kind == GenKind.video ? 'Filming your video…' : 'Painting your image…')
          : 'Waiting for a free machine…');
      await Future<void>.delayed(pollEvery);
      final getUrl = (j['urls'] is Map ? j['urls']['get'] : null) as String? ??
          'https://api.replicate.com/v1/predictions/${j['id']}';
      j = jsonDecode((await send(() => client.get(Uri.parse(getUrl), headers: headers))).body) as Map<String, dynamic>;
    }
    final url = replicateOutputUrl(j['output']);
    if (url == null) throw const GenerationException('Replicate finished but returned no file.');
    onStatus?.call('Downloading…');
    return download(url, r.kind == GenKind.image ? 'image/png' : 'video/mp4',
        headers: {'Authorization': 'Bearer $apiKey'});
  }
}

Generator makeGenerator(AiProvider p, String apiKey, String model, {http.Client? client}) {
  final c = client ?? http.Client();
  return switch (p) {
    AiProvider.openai => OpenAiGenerator(c, apiKey, model),
    AiProvider.gemini => GeminiGenerator(c, apiKey, model),
    AiProvider.replicate => ReplicateGenerator(c, apiKey, model),
  };
}
