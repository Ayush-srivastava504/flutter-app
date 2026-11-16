import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:video_editor_app/ai/gen/ai_key_store.dart';
import 'package:video_editor_app/ai/gen/ai_provider.dart';
import 'package:video_editor_app/ai/gen/generation_service.dart';
import 'package:video_editor_app/ai/gen/generators.dart';

/// BYOK image/video generation: request shapes, response parsing and error
/// messages, against fake HTTP — no network, no keys.
void main() {
  const portrait = GenRequest(prompt: 'a red fox', kind: GenKind.image, aspect: 9 / 16);
  const landscapeVideo = GenRequest(prompt: 'waves', kind: GenKind.video, aspect: 16 / 9, durationSec: 30);
  final png = [137, 80, 78, 71];

  group('shapes', () {
    test('nearest ratio', () {
      expect(nearestRatio(9 / 16, geminiImageRatios), '9:16');
      expect(nearestRatio(4 / 5, geminiImageRatios), '4:5');
      expect(nearestRatio(1.0, replicateImageRatios), '1:1');
      expect(openAiImageSize(9 / 16), '1024x1536');
      expect(openAiImageSize(16 / 9), '1536x1024');
      expect(openAiImageSize(1), '1024x1024');
    });

    test('gemini video duration is clamped to 3–15 s and shape to 9:16 / 16:9', () {
      final b = geminiBody('m', landscapeVideo);
      expect(b['response_format'], {'type': 'video', 'aspect_ratio': '16:9', 'duration': '15s'});
      expect(b['input'], 'waves');
    });

    test('replicate sends prompt, aspect ratio and (for video) duration', () {
      expect(replicateBody(portrait), {
        'input': {'prompt': 'a red fox', 'aspect_ratio': '9:16'}
      });
      expect((replicateBody(landscapeVideo)['input'] as Map)['duration'], 30);
    });

    test('providers say what they can make', () {
      expect(AiProvider.openai.supports(GenKind.video), isFalse);
      expect(AiProvider.gemini.supports(GenKind.video), isTrue);
      expect(AiProvider.replicate.supports(GenKind.image), isTrue);
    });
  });

  group('OpenAI', () {
    test('posts to images/generations and decodes b64_json', () async {
      late http.Request seen;
      final client = MockClient((req) async {
        seen = req;
        return http.Response(jsonEncode({'data': [{'b64_json': base64Encode(png)}]}), 200);
      });
      final m = await OpenAiGenerator(client, 'sk-test', 'gpt-image-1').generate(portrait);
      expect(seen.url.toString(), 'https://api.openai.com/v1/images/generations');
      expect(seen.headers['Authorization'], 'Bearer sk-test');
      expect(jsonDecode(seen.body), {'model': 'gpt-image-1', 'prompt': 'a red fox', 'size': '1024x1536', 'n': 1});
      expect(m.bytes, png);
      expect(m.extension, 'png');
    });

    test('a bad key gives a clear message', () async {
      final client = MockClient((_) async => http.Response(jsonEncode({'error': {'message': 'Incorrect API key'}}), 401));
      expect(
        () => OpenAiGenerator(client, 'bad', 'gpt-image-1').generate(portrait),
        throwsA(isA<GenerationException>()
            .having((e) => e.message, 'message', contains('rejected the API key (Incorrect API key)'))),
      );
    });

    test('video is refused without a network call', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      });
      await expectLater(OpenAiGenerator(client, 'k', 'm').generate(landscapeVideo), throwsA(isA<GenerationException>()));
      expect(calls, 0);
    });
  });

  group('Gemini', () {
    test('reads base64 from steps[model_output].content[type=image]', () async {
      late http.Request seen;
      final client = MockClient((req) async {
        seen = req;
        return http.Response(
            jsonEncode({
              'steps': [
                {'type': 'user_input', 'content': []},
                {
                  'type': 'model_output',
                  'content': [
                    {'type': 'text', 'text': 'Here you go'},
                    {'type': 'image', 'mime_type': 'image/jpeg', 'data': base64Encode(png)},
                  ]
                }
              ]
            }),
            200);
      });
      final m = await GeminiGenerator(client, 'AIza', 'gemini-nano-banana-2.1').generate(portrait);
      expect(seen.url.toString(), 'https://generativelanguage.googleapis.com/v1beta/interactions');
      expect(seen.headers['x-goog-api-key'], 'AIza');
      expect((jsonDecode(seen.body) as Map)['response_format'], {'type': 'image', 'aspect_ratio': '9:16'});
      expect(m.bytes, png);
      expect(m.extension, 'jpg');
    });

    test('older outputs[] responses still work', () {
      final item = geminiMediaItem({
        'outputs': [
          {'type': 'video', 'mime_type': 'video/mp4', 'data': 'AAAA'}
        ]
      }, GenKind.video);
      expect(item, ('AAAA', null, 'video/mp4'));
    });

    test('no media in the answer → asks to reword', () async {
      final client = MockClient((_) async => http.Response(
          jsonEncode({
            'steps': [
              {'type': 'model_output', 'content': [{'type': 'text', 'text': 'I cannot'}]}
            ]
          }),
          200));
      expect(() => GeminiGenerator(client, 'k', 'm').generate(portrait),
          throwsA(isA<GenerationException>().having((e) => e.message, 'm', contains('rewording'))));
    });
  });

  group('Replicate', () {
    test('creates a prediction, polls until it succeeds, downloads with the token', () async {
      final calls = <String>[];
      var polls = 0;
      final client = MockClient((req) async {
        calls.add('${req.method} ${req.url}');
        if (req.method == 'POST') {
          expect(req.headers['Prefer'], 'wait=60');
          return http.Response(
              jsonEncode({'id': 'p1', 'status': 'starting', 'urls': {'get': 'https://api.replicate.com/v1/predictions/p1'}}),
              201);
        }
        if (req.url.path.endsWith('/p1')) {
          polls++;
          return http.Response(
              jsonEncode(polls < 2
                  ? {'id': 'p1', 'status': 'processing'}
                  : {'id': 'p1', 'status': 'succeeded', 'output': ['https://replicate.delivery/x.mp4']}),
              200);
        }
        expect(req.headers['Authorization'], 'Bearer r8_x');
        return http.Response.bytes([1, 2, 3], 200, headers: {'content-type': 'video/mp4'});
      });
      final statuses = <String>[];
      final m = await ReplicateGenerator(client, 'r8_x', 'vidu/q3-turbo', pollEvery: Duration.zero)
          .generate(landscapeVideo, onStatus: statuses.add);
      expect(calls.first, 'POST https://api.replicate.com/v1/models/vidu/q3-turbo/predictions');
      expect(polls, 2);
      expect(m.bytes, [1, 2, 3]);
      expect(m.extension, 'mp4');
      expect(statuses, contains('Filming your video…'));
    });

    test('a failed prediction shows Replicate\'s error', () async {
      final client = MockClient((_) async =>
          http.Response(jsonEncode({'id': 'p', 'status': 'failed', 'error': 'NSFW content detected'}), 201));
      expect(() => ReplicateGenerator(client, 'k', 'a/b', pollEvery: Duration.zero).generate(portrait),
          throwsA(isA<GenerationException>().having((e) => e.message, 'm', contains('NSFW content detected'))));
    });

    test('output shapes', () {
      expect(replicateOutputUrl('https://a'), 'https://a');
      expect(replicateOutputUrl(['https://b', 'https://c']), 'https://b');
      expect(replicateOutputUrl({'url': 'https://d'}), 'https://d');
      expect(replicateOutputUrl(null), isNull);
    });
  });

  group('GenerationJob', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('gen_job'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('needs a key, uses the model override, saves into generated_media', () async {
      final keys = MemoryAiKeyStore();
      final job = GenerationJob(keys, documentsDir: () async => dir);
      await expectLater(job.run(AiProvider.openai, portrait),
          throwsA(isA<GenerationException>().having((e) => e.message, 'm', contains('Add your OpenAI API key'))));

      await keys.setKey(AiProvider.openai, '  sk-1  ');
      await keys.setModelOverride(AiProvider.openai, GenKind.image, 'gpt-image-2');
      String? usedModel, usedKey;
      final path = await job.run(AiProvider.openai, portrait, make: (k, m) {
        usedKey = k;
        usedModel = m;
        return OpenAiGenerator(
            MockClient((_) async => http.Response(jsonEncode({'data': [{'b64_json': base64Encode(png)}]}), 200)), k, m);
      });
      expect(usedKey, 'sk-1');
      expect(usedModel, 'gpt-image-2');
      expect(path, startsWith('${dir.path}${Platform.pathSeparator}generated_media'));
      expect(File(path).readAsBytesSync(), png);
      expect(await keys.ready(GenKind.image), [AiProvider.openai]);
      expect(await keys.ready(GenKind.video), isEmpty, reason: 'OpenAI cannot make videos');
    });
  });
}
