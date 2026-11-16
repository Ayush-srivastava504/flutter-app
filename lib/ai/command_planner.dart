/// Turns a typed request ("speed up 2x and make it black and white") into
/// a list of [EditAction]s.
///
/// [LocalCommandPlanner] is a deterministic, on-device, rule-based parser:
/// no network, no model download, so the app stays offline (docs/FACTS.md
/// F-30..F-32). [AssistantPlanner] is the seam where a language-model
/// planner could be plugged in later — it would only need to return the
/// same [AssistantPlan]; execution, undo and safety stay unchanged.
library command_planner;

import '../models/clip_x.dart' show maxClipSpeed, minClipSpeed;
import 'edit_action.dart';

class AssistantPlan {
  final List<EditAction> actions;

  /// Parts of the request the planner could not turn into an action.
  final List<String> unrecognized;

  const AssistantPlan(this.actions, [this.unrecognized = const []]);

  bool get isEmpty => actions.isEmpty;
}

abstract class AssistantPlanner {
  Future<AssistantPlan> plan(String request);
}

/// Example requests shown as tappable chips in the assistant sheet. Every
/// one of these must parse (covered by a test).
const List<String> assistantExamples = [
  'Remove silences',
  'Auto polish',
  'Make it black and white',
  'Anime style',
  'Gothic look',
  'Speed up 2x',
  'Trim the first 2 seconds',
  'Add text "Hello"',
  'Dissolve between all clips',
  'Make it square',
  'Blur background',
  'Fade music out 2s',
];

class LocalCommandPlanner implements AssistantPlanner {
  const LocalCommandPlanner();

  @override
  Future<AssistantPlan> plan(String request) async => parse(request);

  /// Synchronous and pure, so it is unit-tested directly.
  AssistantPlan parse(String request) {
    // Pull quoted strings out first so their contents are never split on
    // "and" or mistaken for commands.
    final quotes = <String>[];
    var text = request.replaceAllMapped(RegExp('"([^"]*)"|“([^”]*)”'), (m) {
      quotes.add((m[1] ?? m[2] ?? '').trim());
      return ' \u0001${quotes.length - 1}\u0001 ';
    });
    text = text.toLowerCase();
    // "black and white" must survive the split on "and".
    text = text.replaceAll(RegExp(r'black\s*(?:and|&|n)\s*white|b\s*&\s*w|\bbw\b'), 'mono');

    final actions = <EditAction>[];
    final unrecognized = <String>[];
    for (final raw in text.split(RegExp(r'\s*(?:[;\n]|,|\.(?=\s|$)|\band then\b|\bthen\b|\band\b|\balso\b)\s*'))) {
      final clause = raw.trim();
      if (clause.isEmpty) continue;
      final parsed = _parseClause(clause, quotes);
      if (parsed.isEmpty) {
        unrecognized.add(_restore(clause, quotes));
      } else {
        actions.addAll(parsed);
      }
    }
    return AssistantPlan(actions, unrecognized);
  }

  static String _restore(String clause, List<String> quotes) =>
      clause.replaceAllMapped(RegExp('\u0001(\\d+)\u0001'), (m) => '"${quotes[int.parse(m[1]!)]}"').trim();

  static bool _has(String s, String pattern) => RegExp(pattern).hasMatch(s);

  /// Seconds/milliseconds mentioned in [s], in ms; null if none.
  static int? _durationMs(String s) {
    final m = RegExp(r'(\d+(?:\.\d+)?)\s*(ms|milliseconds?|s|sec|secs|seconds?)\b').firstMatch(s);
    if (m == null) return null;
    final v = double.parse(m[1]!);
    return (m[2]!.startsWith('m') ? v : v * 1000).round();
  }

  static double? _percent(String s) {
    final m = RegExp(r'(\d+(?:\.\d+)?)\s*(?:%|percent)').firstMatch(s);
    return m == null ? null : double.parse(m[1]!) / 100;
  }

  static double? _multiplier(String s) {
    final m = RegExp(r'(\d+(?:\.\d+)?)\s*(?:x|times)\b').firstMatch(s) ?? RegExp(r'\bx\s*(\d+(?:\.\d+)?)').firstMatch(s);
    return m == null ? null : double.parse(m[1]!);
  }

  static const _ordinals = {'first': 1, 'second': 2, 'third': 3, 'fourth': 4, 'fifth': 5, 'last': -1};

  static ClipScope _scope(String s) {
    final n = RegExp(r'\bclip\s*#?\s*(\d+)').firstMatch(s);
    if (n != null) return ClipScope.index(int.parse(n[1]!));
    final o = RegExp(r'\b(first|second|third|fourth|fifth|last)\s+clip\b').firstMatch(s);
    if (o != null) return ClipScope.index(_ordinals[o[1]]!);
    if (_has(s, r'\b(all|every|each)\b|\beverything\b|\bwhole (video|project|timeline)\b|\bclips\b')) {
      return const ClipScope.all();
    }
    return const ClipScope.selected();
  }

  List<EditAction> _parseClause(String s, List<String> quotes) {
    final scope = _scope(s);

    if (_has(s, r'^\s*undo\b')) return const [UndoEdit()];
    if (_has(s, r'^\s*redo\b')) return const [RedoEdit()];

    // --- smart tools -----------------------------------------------------
    if (_has(s, r'\b(silences|silent|dead air|pauses|quiet parts?)\b') ||
        (_has(s, r'\bsilence\b') && _has(s, r'\b(remove|cut|trim|delete|skip|strip)\b'))) {
      return [RunSmartTool(SmartTool.removeSilences, scope)];
    }
    if (_has(s, r'\bscenes?\b')) return [RunSmartTool(SmartTool.splitScenes, scope)];
    if (_has(s, r'\b(balance|normali[sz]e|level|even out)\b') && _has(s, r'\b(audio|volume|sound|loudness|levels?)\b')) {
      return const [RunSmartTool(SmartTool.balanceLoudness, ClipScope.all())];
    }
    if (_has(s, r'\b(auto[\s-]?(edit|polish|enhance)|polish|magic|make it (look )?(good|better|nice|pro))\b')) {
      return const [RunSmartTool(SmartTool.autoPolish, ClipScope.all())];
    }

    // --- music -----------------------------------------------------------
    if (_has(s, r'\bduck')) {
      return [SetDucking(!_has(s, r"\b(no|off|stop|disable|don't|dont|remove)\b"))];
    }
    if (_has(s, r'\b(music|song|soundtrack|track)\b')) {
      if (_has(s, r'\bfade')) {
        final ms = _durationMs(s) ?? 1000;
        final fadeIn = _has(s, r'\bin\b');
        final fadeOut = _has(s, r'\bout\b');
        return [
          SetMusicFade(
            fadeInMs: fadeIn || !fadeOut ? ms : null,
            fadeOutMs: fadeOut || !fadeIn ? ms : null,
          ),
        ];
      }
      if (_has(s, r'\b(remove|delete|no|without|drop)\b')) return const [RemoveMusic()];
      if (_has(s, r'\b(fit|end|stop|cut)\b.*\b(video|end|timeline)\b')) return const [FitMusicToTimeline()];
      final pct = _percent(s);
      if (pct != null) return [SetMusicVolume(pct.clamp(0.0, 1.0).toDouble())];
      if (_has(s, r'\b(mute|silence)\b')) return const [SetMusicVolume(0)];
      if (_has(s, r'\b(quieter|softer|lower|down)\b')) return const [SetMusicVolume(0.4)];
      if (_has(s, r'\b(louder|higher|up|full)\b')) return const [SetMusicVolume(1)];
      return const [];
    }

    // --- frame shape -----------------------------------------------------
    final ratio = RegExp(r'\b(\d{1,2})\s*[:/]\s*(\d{1,2})\b').firstMatch(s);
    if (ratio != null) {
      final w = int.parse(ratio[1]!);
      final h = int.parse(ratio[2]!);
      if (w > 0 && h > 0) return [SetAspectRatio(w / h, '$w:$h')];
    }
    if (_has(s, r'\bsquare\b')) return const [SetAspectRatio(1, '1:1')];
    if (_has(s, r'\b(vertical|portrait|tiktok|reels?|shorts|story|stories)\b')) {
      return const [SetAspectRatio(9 / 16, '9:16')];
    }
    if (_has(s, r'\b(landscape|horizontal|widescreen|youtube)\b')) return const [SetAspectRatio(16 / 9, '16:9')];

    // --- text ------------------------------------------------------------
    final textMatch =
        RegExp(r'\b(?:text|title|caption|subtitle|write|say(?:ing|s)?)\b[:\s]*(?:saying|that says|says|of)?\s*(.*)$')
            .firstMatch(s);
    if (textMatch != null && !_has(s, r'\b(remove|delete)\b')) {
      final content = _restore(textMatch[1] ?? '', quotes).replaceAll('"', '').trim();
      if (content.isNotEmpty) return [AddText(_originalCase(content, quotes))];
      return const [AddText('Tap to edit')];
    }

    // --- transitions -----------------------------------------------------
    final transition = _transition(s);
    if (transition != null) {
      final between = _has(s, r'\b(transitions|between|everywhere)\b');
      return [SetTransition(between ? const ClipScope.all() : scope, transition)];
    }

    // --- trim (before delete: "remove the first 2 seconds") --------------
    final ms = _durationMs(s);
    if (ms != null && ms > 0) {
      final removes = _has(s, r'\b(trim|cut|remove|chop|shave|delete|drop|skip)\b');
      if (_has(s, r'\b(trim|cut|shorten|limit)\b.*\bto\b')) {
        return [TrimClip(scope, TrimKind.keepFirst, ms)];
      } else if (removes) {
        if (_has(s, r'\b(last|end|ending|final)\b')) return [TrimClip(scope, TrimKind.removeEnd, ms)];
        if (_has(s, r'\b(first|start|beginning|opening|intro)\b')) return [TrimClip(scope, TrimKind.removeStart, ms)];
      } else if (_has(s, r'\b(keep|show|lasts?|duration|long)\b')) {
        // "keep the last 3 seconds" needs the clip length, which a
        // planner doesn't have; leave it unrecognised rather than guess.
        if (_has(s, r'\bkeep\b.*\blast\b')) return const [];
        return [TrimClip(scope, TrimKind.keepFirst, ms)];
      }
    }

    // --- structure -------------------------------------------------------
    if (_has(s, r'\bsplit\b|\bcut (here|at)\b')) return const [SplitAtPlayhead()];
    if (_has(s, r'\b(duplicate|copy|clone)\b')) return [DuplicateClips(scope)];

    // --- look / colour (before delete: "remove the filter") ---------------
    if (_has(s, r'\b(no|remove|reset|clear|delete)\b.*\b(look|filter|filters|effect|colou?rs?|grade)\b') ||
        _has(s, r'\boriginal colou?rs?\b')) {
      return [SetLook(scope, null), ResetColor(scope)];
    }
    for (final (pattern, id) in _lookWords) {
      if (_has(s, pattern)) {
        final pct = _percent(s);
        return [SetLook(scope, id, strength: pct?.clamp(0.0, 1.0).toDouble() ?? 1.0)];
      }
    }

    final amount = _percent(s);
    if (_has(s, r'\b(brighter|brighten|lighter|lighten)\b') || _has(s, r'\b(more|increase|raise|boost)\b.*\bbrightness\b')) {
      return [AdjustColor(scope, brightness: amount ?? 0.15)];
    }
    if (_has(s, r'\b(darker|darken|dim|dimmer)\b') || _has(s, r'\b(less|decrease|lower|reduce)\b.*\bbrightness\b')) {
      return [AdjustColor(scope, brightness: -(amount ?? 0.15))];
    }
    if (_has(s, r'\b(less|decrease|lower|reduce)\b.*\bcontrast\b|\bflatter\b')) {
      return [AdjustColor(scope, contrast: -(amount ?? 0.2))];
    }
    if (_has(s, r'\bcontrast\b|\bpunchier\b')) return [AdjustColor(scope, contrast: amount ?? 0.2)];
    if (_has(s, r'\b(less|decrease|lower|reduce)\b.*\bsaturat|\bdesaturate|\bmuted colou?rs?\b')) {
      return [AdjustColor(scope, saturation: -(amount ?? 0.25))];
    }
    if (_has(s, r'\bsaturat|\b(vivid|vibrant|colou?rful)\b')) return [AdjustColor(scope, saturation: amount ?? 0.25)];

    // --- frame fill ------------------------------------------------------
    if (_has(s, r'\bblur')) return [SetFitMode(scope, 'blur')];
    if (_has(s, r'\b(fill|cover)\b|\b(no|remove|without)\b.*\bblack bars\b|\bcrop to\b')) {
      return [SetFitMode(scope, 'fill')];
    }
    if (_has(s, r'\b(fit|letterbox)\b|\bshow (the )?whole\b')) return [SetFitMode(scope, 'fit')];

    // --- delete ----------------------------------------------------------
    if (_has(s, r'\b(delete|remove)\b')) {
      if (_has(s, r'\bclips?\b') || _has(s, r'^(delete|remove)( this| it| that)?$')) return [DeleteClips(scope)];
      return const [];
    }

    // --- speed -----------------------------------------------------------
    final speed = _speed(s);
    if (speed != null) return [SetSpeed(scope, speed.clamp(minClipSpeed, maxClipSpeed).toDouble())];

    // --- audio -----------------------------------------------------------
    if (_has(s, r'\bunmute\b|\b(sound|audio) (back )?on\b')) return [SetMuted(scope, false)];
    if (_has(s, r'\b(mute|silence)\b|\bno (sound|audio)\b|\b(sound|audio) off\b')) return [SetMuted(scope, true)];
    if (_has(s, r'\bvolume\b|\blouder\b|\bquieter\b|\bsofter\b')) {
      if (amount != null) return [SetVolume(scope, amount.clamp(0.0, 1.0).toDouble())];
      if (_has(s, r'\b(quieter|softer|lower|down|half)\b')) return [SetVolume(scope, 0.5)];
      return [SetVolume(scope, 1)];
    }

    // --- orientation -----------------------------------------------------
    if (_has(s, r'\brotate|\bturn\b')) {
      if (_has(s, r'\b180\b|upside')) return [RotateClip(scope, 2)];
      if (_has(s, r'\b(left|counter|anti)')) return [RotateClip(scope, -1)];
      return [RotateClip(scope, 1)];
    }
    if (_has(s, r'\bupside down\b')) return [RotateClip(scope, 2)];
    if (_has(s, r'\b(flip|mirror)')) {
      return [FlipClip(scope, horizontal: !_has(s, r'\b(vertical|vertically|upside)'))];
    }

    return const [];
  }

  /// Quoted text was lower-cased along with everything else only when it
  /// was *not* quoted; quoted text is restored verbatim by [_restore], so
  /// this only tidies unquoted content ("add text hello" -> "Hello").
  static String _originalCase(String content, List<String> quotes) {
    if (quotes.contains(content)) return content;
    return content[0].toUpperCase() + content.substring(1);
  }

  /// Words -> look id (`lookPresets`), most specific first.
  static const List<(String, String)> _lookWords = [
    (r'\b(blockbuster|hollywood grade)\b', 'pro_blockbuster'),
    (r'\bbleach( bypass)?\b', 'pro_bleach'),
    (r'\bcross[\s-]?process', 'pro_cross'),
    (r'\bmatte\b', 'pro_matte'),
    (r'\bairy\b', 'pro_airy'),
    (r'\bportrait\b', 'pro_portrait'),
    (r'\blandscape (look|grade|filter)\b|\bnature\b', 'pro_landscape'),
    (r'\bfood\b', 'pro_food'),
    (r'\bnight( city)?\b', 'pro_night'),
    (r'\bfine[\s-]?art\b', 'pro_mono'),
    (r'\b(clean|professional|pro)\b', 'pro_clean'),
    (r'\bgoth(ic)?\b|\bdark fantasy\b', 'gothic'),
    (r'\b(anime|manga|ghibli)\b', 'anime'),
    (r'\b(cartoon|toon)\b', 'cartoon'),
    (r'\b(comic|pop art)\b', 'comic'),
    (r'\b(sketch|pencil|drawing)\b', 'sketch'),
    (r'\b(painting|painted|oil)\b', 'oil'),
    (r'\bduo ?tone\b', 'duotone'),
    (r'\bnoir\b', 'noir'),
    (r'\b(mono|monochrome|gr[ae]yscale)\b', 'mono'),
    (r'\bsepia\b', 'sepia'),
    (r'\b(cinematic|movie|hollywood|teal and orange|orange and teal)\b', 'cinematic'),
    (r'\b(moody|dark mood)\b', 'moody'),
    (r'\b(dreamy|soft|pastel)\b', 'dreamy'),
    (r'\b(golden hour|golden|sunset)\b', 'golden'),
    (r'\b(vhs|camcorder|90s)\b', 'vhs'),
    (r'\b(polaroid|instant)\b', 'polaroid'),
    (r'\bfaded\b', 'faded'),
    (r'\b(film|analog|35 ?mm|grainy)\b', 'film'),
    (r'\b(vintage|retro|old)\b', 'vintage'),
    (r'\b(cyberpunk|neon|synthwave)\b', 'cyberpunk'),
    (r'\bglitch', 'glitch'),
    (r'\b(pixel|pixelated|8 ?bit)\b', 'pixel'),
    (r'\b(x-?ray|negative|invert(ed)?)\b', 'xray'),
    (r'\b(crisp|sharpen|sharper)\b', 'crisp'),
    (r'\b(pop|punchy)\b', 'pop'),
    (r'\bvignette\b', 'vignette'),
    (r'\b(cool|cooler|cold|blue tint)\b', 'cool'),
    (r'\b(warm|warmer)\b', 'warm'),
  ];

  static String? _transition(String s) {
    final mentionsTransition = _has(s, r'\btransitions?\b');
    if (mentionsTransition && _has(s, r'\b(no|remove|without|clear|delete|hard cuts?)\b')) return 'cut';
    if (_has(s, r'\b(dissolve|cross[\s-]?fade|cross[\s-]?dissolve)')) return 'dissolve';
    if (_has(s, r'\bwipe')) return 'wipeleft';
    if (_has(s, r'\bslide')) return 'slideleft';
    if (_has(s, r'\bcircle|\biris\b')) return 'circleopen';
    if (mentionsTransition && _has(s, r'\bzoom')) return 'zoomin';
    if (_has(s, r'\bfade')) return 'fade';
    if (mentionsTransition && _has(s, r'\bcuts?\b')) return 'cut';
    if (mentionsTransition) return 'dissolve';
    return null;
  }

  static double? _speed(String s) {
    if (_has(s, r'\b(normal|regular|original|reset)\b.*\bspeed\b|\bspeed\b.*\b(normal|reset)\b')) return 1.0;
    final x = _multiplier(s);
    final pct = _has(s, r'\bspeed\b') ? _percent(s) : null;
    final slow = _has(s, r'\bslow|\bslo[\s-]?mo\b');
    final fast = _has(s, r'\b(speed up|faster|fast|fast[\s-]?forward|time[\s-]?lapse|quicker)\b');
    if (_has(s, r'\bhalf\b.*\bspeed\b')) return 0.5;
    if (_has(s, r'\b(double|twice)\b.*\b(speed|fast)')) return 2.0;
    if (x != null) {
      // "slow down 2x" means half speed, not double.
      return slow && x > 1 ? 1 / x : x;
    }
    if (pct != null) return pct;
    if (slow) return 0.5;
    if (fast) return 2.0;
    final bare = RegExp(r'\bspeed\b\D*(\d+(?:\.\d+)?)').firstMatch(s);
    if (bare != null) return double.parse(bare[1]!);
    return null;
  }
}
