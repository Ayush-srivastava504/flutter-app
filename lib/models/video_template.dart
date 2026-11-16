/// Templates: ready-made edits the user fills with their own clips.
///
/// A template is plain data — clip slot lengths, transition, look, effects,
/// titles, music — built only from features the editor already has, so the
/// result is an ordinary project the user can keep editing (nothing is
/// locked, and the export needs no template-specific code).
///
/// Discover (2026-11-13) groups them into four tabs ([DiscoverTab]) and
/// categories ([DiscoverCategory]). **Beat-synced** templates give their
/// slots in beats ([VideoTemplate.beats]) of their library track; the
/// lengths in ms come from that track's bpm, counted from the song's start
/// (every library track starts on a beat), so each cut lands on a beat.
/// Beat templates only use non-overlapping transitions — an xfade would
/// shorten the timeline and push every later cut off the beat.
/// The planning functions are pure and unit-tested.
library video_template;

import 'package:flutter/material.dart' show Color, IconData, Icons;

import 'audio_library.dart';
import 'edit_mode.dart';

class TemplateText {
  final String content;

  /// Negative values count back from the end of the video.
  final int startMs;
  final int endMs;
  final double positionY;
  final double fontSize;
  final bool bold;
  final bool box;
  final String fontFamily;
  const TemplateText(
    this.content,
    this.startMs,
    this.endMs, {
    this.positionY = 0.5,
    this.fontSize = 28,
    this.bold = true,
    this.box = false,
    this.fontFamily = 'Default',
  });
}

/// The four Discover tabs.
enum DiscoverTab {
  youtube('YouTube video', Icons.smart_display_outlined),
  story('Insta story', Icons.amp_stories_outlined),
  post('Insta post', Icons.grid_on_rounded),
  moments('Posts', Icons.celebration_outlined);

  final String label;
  final IconData icon;
  const DiscoverTab(this.label, this.icon);
}

class DiscoverCategory {
  final String id;
  final String label;
  final DiscoverTab tab;
  final IconData icon;

  /// Card gradient (top-left → bottom-right).
  final Color from;
  final Color to;
  const DiscoverCategory(this.id, this.label, this.tab, this.icon, this.from, this.to);
}

const List<DiscoverCategory> discoverCategories = [
  DiscoverCategory('cinematic_vlog', 'Cinematic vlog', DiscoverTab.youtube, Icons.movie_filter_outlined,
      Color(0xFF2B3A55), Color(0xFFCE7B4E)),
  DiscoverCategory('travel', 'Travel', DiscoverTab.youtube, Icons.flight_takeoff_rounded, Color(0xFF0F5E6E), Color(0xFF7CC6B5)),
  DiscoverCategory('gaming', 'Gaming', DiscoverTab.youtube, Icons.sports_esports_outlined, Color(0xFF3B1E6E), Color(0xFF16C6E0)),
  DiscoverCategory('photo_dump', 'Travel & stories photo dump', DiscoverTab.story, Icons.photo_library_outlined,
      Color(0xFF6E4A2B), Color(0xFFE9C38A)),
  DiscoverCategory('story_beat', 'On the beat', DiscoverTab.story, Icons.graphic_eq, Color(0xFF5B1236), Color(0xFFFF6A5C)),
  DiscoverCategory('collage', 'Aesthetic photo collage', DiscoverTab.post, Icons.auto_awesome_mosaic_outlined,
      Color(0xFF5A5148), Color(0xFFD9C7B0)),
  DiscoverCategory('quotes', 'Minimalist quotes', DiscoverTab.post, Icons.format_quote_rounded, Color(0xFF1C1C1E), Color(0xFF6B6B70)),
  DiscoverCategory('fashion', 'Fashion & outfit', DiscoverTab.post, Icons.checkroom_outlined, Color(0xFF7A2E4E), Color(0xFFF2A7B8)),
  DiscoverCategory('birthday', 'Birthday celebration', DiscoverTab.moments, Icons.cake_outlined, Color(0xFF8A3B12), Color(0xFFFFC857)),
  DiscoverCategory('love', 'Love stories', DiscoverTab.moments, Icons.favorite_outline_rounded, Color(0xFF6B1A35), Color(0xFFF07C8C)),
];

DiscoverCategory? discoverCategoryById(String? id) {
  for (final c in discoverCategories) {
    if (c.id == id) return c;
  }
  return null;
}

class VideoTemplate {
  final String id;
  final String name;
  final String tagline;
  final EditMode mode;

  /// Fixed slot lengths in ms (ignored when [beats] is set — see [slotsMs]).
  final List<int> fixedSlotsMs;

  /// Beat-synced slots: each slot's length in beats of [musicId]'s tempo.
  final List<int>? beats;
  final String transition;
  final String? look;
  final double lookStrength;

  /// Effect per slot, cycling (null = none).
  final List<String?> effects;
  final List<TemplateText> texts;

  /// Id in `audioLibrary` (preferred) or `bundledAudioLibrary`, or null.
  final String? musicId;
  final bool duckMusic;

  /// Discover category id ([discoverCategories]).
  final String category;

  /// Frame shape override (e.g. 4:5 for an Insta post); otherwise the
  /// mode's locked shape, or the first video's.
  final double? aspect;

  const VideoTemplate({
    required this.id,
    required this.name,
    required this.tagline,
    required this.mode,
    required this.category,
    List<int> slotsMs = const [],
    this.beats,
    this.transition = 'cut',
    this.look,
    this.lookStrength = 1.0,
    this.effects = const [null],
    this.texts = const [],
    this.musicId,
    this.duckMusic = false,
    this.aspect,
  }) : fixedSlotsMs = slotsMs;

  /// Tempo of the template's music (0 when it has none / no tempo).
  int get bpm => audioLibrary.where((s) => s.id == musicId).firstOrNull?.bpm ?? 0;

  bool get isBeatSynced => beats != null && bpm > 0;

  /// One beat in ms (0 when not beat-synced).
  double get beatMs => isBeatSynced ? 60000 / bpm : 0;

  /// Slot lengths in ms. Beat slots are rounded from the running beat
  /// count, so rounding never accumulates: slot k ends exactly on beat
  /// Σbeats[0..k] (to the nearest ms).
  List<int> get slotsMs {
    if (!isBeatSynced) return fixedSlotsMs;
    final out = <int>[];
    var beatsSoFar = 0;
    for (final b in beats!) {
      final start = (beatsSoFar * beatMs).round();
      beatsSoFar += b;
      out.add((beatsSoFar * beatMs).round() - start);
    }
    return out;
  }

  int get suggestedClips => slotsMs.length;
  int get lengthMs => slotsMs.fold(0, (a, b) => a + b);
  DiscoverCategory? get discoverCategory => discoverCategoryById(category);
}

const List<VideoTemplate> videoTemplates = [
  // ---- YouTube video ----------------------------------------------------
  VideoTemplate(
    id: 'tpl_cine_vlog',
    name: 'Cinematic vlog',
    tagline: 'Wide shots, slow zooms, film colour and a title card',
    mode: EditMode.youtube,
    category: 'cinematic_vlog',
    slotsMs: [4000, 3500, 3500, 4000, 5000],
    transition: 'dissolve',
    look: 'cinematic',
    effects: ['fx_zoom_in', 'fx_pan', null, 'fx_zoom_out', 'fx_dreamy'],
    texts: [
      TemplateText('A DAY IN', 300, 3200, positionY: 0.44, fontSize: 30, fontFamily: 'Serif', bold: false),
      TemplateText('my life', 900, 3600, positionY: 0.56, fontSize: 22, fontFamily: 'Cursive', bold: false),
    ],
    musicId: 'cine_rising_tide',
    duckMusic: true,
  ),
  VideoTemplate(
    id: 'tpl_yt_vlog',
    name: 'Daily vlog',
    tagline: 'Talking clips with clean sound and a title card',
    mode: EditMode.youtube,
    category: 'cinematic_vlog',
    slotsMs: [6000, 6000, 6000, 6000, 6000],
    transition: 'dissolve',
    look: 'golden',
    lookStrength: 0.6,
    texts: [TemplateText('Day 1', 0, 2500, positionY: 0.15, fontSize: 30)],
    musicId: 'lofi_coffee_break',
    duckMusic: true,
  ),
  VideoTemplate(
    id: 'tpl_yt_travel',
    name: 'Travel film',
    tagline: 'Landscapes that drift, cut on the beat of a hopeful track',
    mode: EditMode.youtube,
    category: 'travel',
    beats: [8, 8, 4, 4, 8, 8],
    look: 'pro_landscape',
    effects: ['fx_pan', 'fx_zoom_in', null, 'fx_zoom_out', 'fx_pan', 'fx_glow'],
    texts: [TemplateText('WHERE TO NEXT?', -4000, -300, positionY: 0.5, fontSize: 30)],
    musicId: 'acoustic_paper_planes',
  ),
  VideoTemplate(
    id: 'tpl_yt_roadtrip',
    name: 'Road trip',
    tagline: 'Golden-hour colour, whip pans between places',
    mode: EditMode.youtube,
    category: 'travel',
    slotsMs: [3000, 2500, 2500, 2500, 3500],
    transition: 'whip',
    look: 'golden',
    effects: ['fx_zoom_in', null, 'fx_pan'],
    texts: [TemplateText('ROAD TRIP', 0, 2600, positionY: 0.2, fontSize: 34)],
    musicId: 'pop_good_days',
  ),
  VideoTemplate(
    id: 'tpl_yt_intro',
    name: 'Channel intro',
    tagline: 'Three punchy shots under your channel name',
    mode: EditMode.youtube,
    category: 'gaming',
    slotsMs: [2500, 2500, 3500],
    transition: 'dissolve',
    look: 'pro_clean',
    effects: ['fx_zoom_in', 'fx_pan', 'fx_zoom_out'],
    texts: [
      TemplateText('YOUR CHANNEL', 0, 3000, positionY: 0.42, fontSize: 34),
      TemplateText('new video every week', 600, 3000, positionY: 0.56, fontSize: 18, bold: false),
      TemplateText('Subscribe', -3000, -200, positionY: 0.82, fontSize: 22, box: true),
    ],
    musicId: 'synth_neon_highway',
  ),
  VideoTemplate(
    id: 'tpl_gaming_montage',
    name: 'Gaming montage',
    tagline: 'Neon colour, glitch hits and shakes on every beat',
    mode: EditMode.youtube,
    category: 'gaming',
    beats: [4, 4, 2, 2, 4, 4, 2, 2, 8],
    look: 'cyberpunk',
    effects: ['fx_flash', 'fx_shake', 'fx_glitch', 'fx_pulse', 'fx_glow'],
    texts: [TemplateText('GG', -3500, -300, positionY: 0.5, fontSize: 44, fontFamily: 'Monospace')],
    musicId: 'house_night_pulse',
  ),

  // ---- Insta story --------------------------------------------------------
  VideoTemplate(
    id: 'tpl_ig_travel',
    name: 'Travel reel',
    tagline: 'Six quick shots, cinematic colour',
    mode: EditMode.insta,
    category: 'photo_dump',
    slotsMs: [1500, 1500, 1500, 1500, 1500, 2500],
    transition: 'cut',
    look: 'cinematic',
    effects: ['fx_zoom_in', null, 'fx_pulse', null, 'fx_pan', 'fx_zoom_out'],
    texts: [TemplateText('Weekend away', 0, 2200, positionY: 0.3, fontSize: 32)],
    musicId: 'synth_neon_highway',
  ),
  VideoTemplate(
    id: 'tpl_story_dump',
    name: 'Photo dump',
    tagline: 'Ten photos, one per beat, soft film look',
    mode: EditMode.insta,
    category: 'photo_dump',
    beats: [2, 2, 2, 2, 2, 2, 2, 2, 2, 4],
    look: 'film',
    effects: ['fx_zoom_in', 'fx_pan', 'fx_zoom_out', 'fx_glow'],
    texts: [TemplateText('photo dump', 0, 2400, positionY: 0.12, fontSize: 24, fontFamily: 'Cursive', bold: false)],
    musicId: 'lofi_rainy_window',
  ),
  VideoTemplate(
    id: 'tpl_story_diary',
    name: 'Story diary',
    tagline: 'Slow, warm and dreamy — memories from a trip',
    mode: EditMode.insta,
    category: 'photo_dump',
    slotsMs: [2500, 2500, 2500, 2500, 3000],
    transition: 'fade',
    look: 'faded',
    effects: ['fx_dreamy', 'fx_pan', 'fx_zoom_in'],
    texts: [TemplateText('little moments', 300, 2600, positionY: 0.8, fontSize: 24, fontFamily: 'Serif', bold: false)],
    musicId: 'chill_sunday',
  ),
  VideoTemplate(
    id: 'tpl_ig_beat',
    name: 'Beat cut',
    tagline: 'Fast cuts on the beat with shake and flash',
    mode: EditMode.insta,
    category: 'story_beat',
    beats: [2, 2, 2, 2, 2, 2, 2, 2],
    look: 'pop',
    effects: ['fx_flash', 'fx_shake', 'fx_pulse', 'fx_shake'],
    musicId: 'pop_bright_side',
  ),
  VideoTemplate(
    id: 'tpl_story_glow',
    name: 'Night glow',
    tagline: 'City lights that bloom, one cut every beat',
    mode: EditMode.insta,
    category: 'story_beat',
    beats: [2, 2, 2, 2, 2, 2, 4, 4],
    look: 'pro_night',
    effects: ['fx_glow', 'fx_pulse', 'fx_glow', 'fx_flash'],
    musicId: 'house_night_pulse',
  ),

  // ---- Insta post (4:5) -------------------------------------------------
  VideoTemplate(
    id: 'tpl_post_collage',
    name: 'Aesthetic collage',
    tagline: 'Muted tones, gentle zooms, one photo per bar',
    mode: EditMode.normal,
    aspect: 4 / 5,
    category: 'collage',
    beats: [4, 4, 4, 4, 4, 4],
    look: 'pro_matte',
    effects: ['fx_zoom_in', 'fx_zoom_out'],
    texts: [TemplateText('collected moments', -3200, -200, positionY: 0.88, fontSize: 20, fontFamily: 'Serif', bold: false)],
    musicId: 'lofi_late_night',
  ),
  VideoTemplate(
    id: 'tpl_post_quote',
    name: 'Minimalist quote',
    tagline: 'One calm picture and your words in the middle',
    mode: EditMode.normal,
    aspect: 4 / 5,
    category: 'quotes',
    slotsMs: [7000],
    look: 'noir',
    lookStrength: 0.7,
    effects: ['fx_zoom_in'],
    texts: [
      TemplateText('“Less, but better.”', 400, -400, positionY: 0.46, fontSize: 30, fontFamily: 'Serif', bold: false),
      TemplateText('— your name', 1200, -400, positionY: 0.58, fontSize: 16, bold: false),
    ],
    musicId: 'ambient_weightless',
  ),
  VideoTemplate(
    id: 'tpl_post_quote_duo',
    name: 'Quote pair',
    tagline: 'Two pictures, two lines, a soft fade between',
    mode: EditMode.normal,
    aspect: 1,
    category: 'quotes',
    slotsMs: [4500, 4500],
    transition: 'fade',
    look: 'faded',
    texts: [
      TemplateText('slow down.', 300, 4000, positionY: 0.5, fontSize: 30, fontFamily: 'Serif', bold: false),
      TemplateText('breathe.', 5000, -300, positionY: 0.5, fontSize: 30, fontFamily: 'Serif', bold: false),
    ],
    musicId: 'ambient_weightless',
  ),
  VideoTemplate(
    id: 'tpl_post_outfit',
    name: 'Outfit check',
    tagline: 'Look-by-look on the beat with a flash on each change',
    mode: EditMode.normal,
    aspect: 4 / 5,
    category: 'fashion',
    beats: [4, 4, 4, 4, 4, 8],
    look: 'pro_portrait',
    effects: ['fx_flash', 'fx_zoom_in', 'fx_flash', 'fx_pulse'],
    texts: [TemplateText('OOTD', 0, 2000, positionY: 0.12, fontSize: 32)],
    musicId: 'pop_bright_side',
  ),
  VideoTemplate(
    id: 'tpl_ig_product',
    name: 'Product drop',
    tagline: 'Clean, slow zooms for something you sell',
    mode: EditMode.normal,
    aspect: 4 / 5,
    category: 'fashion',
    slotsMs: [2500, 2500, 2500, 3000],
    transition: 'dissolve',
    look: 'pro_clean',
    effects: ['fx_zoom_in'],
    texts: [
      TemplateText('NEW DROP', 0, 2400, positionY: 0.2, fontSize: 34),
      TemplateText('Link in bio', -2600, -100, positionY: 0.75, fontSize: 22, box: true),
    ],
    musicId: 'hiphop_street_lights',
  ),

  // ---- Posts: moments ---------------------------------------------------
  VideoTemplate(
    id: 'tpl_birthday',
    name: 'Birthday wishes',
    tagline: 'Bright colour, confetti-flash cuts on the beat',
    mode: EditMode.insta,
    category: 'birthday',
    beats: [4, 4, 4, 4, 4, 4, 8],
    look: 'pop',
    effects: ['fx_flash', 'fx_zoom_in', 'fx_pulse', 'fx_glow'],
    texts: [
      TemplateText('HAPPY BIRTHDAY', 200, 3400, positionY: 0.2, fontSize: 32),
      TemplateText('make a wish', -3800, -300, positionY: 0.8, fontSize: 24, fontFamily: 'Cursive', bold: false),
    ],
    musicId: 'pop_good_days',
  ),
  VideoTemplate(
    id: 'tpl_birthday_memories',
    name: 'Then & now',
    tagline: 'Old photos to today — warm, slow and sweet',
    mode: EditMode.normal,
    aspect: 4 / 5,
    category: 'birthday',
    slotsMs: [3000, 3000, 3000, 3000, 4000],
    transition: 'dissolve',
    look: 'golden',
    effects: ['fx_pan', 'fx_zoom_in', 'fx_dreamy'],
    texts: [TemplateText('Happy Birthday', -3600, -200, positionY: 0.5, fontSize: 34, fontFamily: 'Cursive', bold: false)],
    musicId: 'acoustic_paper_planes',
  ),
  VideoTemplate(
    id: 'tpl_love_story',
    name: 'Love story',
    tagline: 'Soft glow, slow fades and a line just for them',
    mode: EditMode.insta,
    category: 'love',
    slotsMs: [3000, 3000, 3000, 3000, 4000],
    transition: 'fade',
    look: 'dreamy',
    effects: ['fx_dreamy', 'fx_zoom_in', 'fx_pan'],
    texts: [
      TemplateText('us', 300, 2800, positionY: 0.45, fontSize: 40, fontFamily: 'Cursive', bold: false),
      TemplateText('always & forever', -3600, -300, positionY: 0.8, fontSize: 22, fontFamily: 'Serif', bold: false),
    ],
    musicId: 'lofi_late_night',
  ),
  VideoTemplate(
    id: 'tpl_memories',
    name: 'Memories',
    tagline: 'Soft film look and slow fades for photos',
    mode: EditMode.normal,
    category: 'love',
    slotsMs: [3000, 3000, 3000, 3000, 3000],
    transition: 'fade',
    look: 'film',
    effects: ['fx_pan', 'fx_zoom_in'],
    texts: [TemplateText('Memories', 0, 2800, positionY: 0.5, fontSize: 34, fontFamily: 'Serif', bold: false)],
    musicId: 'ambient_weightless',
  ),
];

VideoTemplate? templateById(String id) {
  for (final t in videoTemplates) {
    if (t.id == id) return t;
  }
  return null;
}

/// What one picked clip becomes in a template.
class TemplateClipPlan {
  /// Trimmed length on the timeline (photo duration for photos).
  final int lengthMs;
  final String? effect;

  /// Transition *out* of this clip (the last clip gets 'cut').
  final String transitionOut;
  const TemplateClipPlan(this.lengthMs, this.effect, this.transitionOut);

  @override
  bool operator ==(Object other) =>
      other is TemplateClipPlan &&
      other.lengthMs == lengthMs &&
      other.effect == effect &&
      other.transitionOut == transitionOut;

  @override
  int get hashCode => Object.hash(lengthMs, effect, transitionOut);

  @override
  String toString() => 'TemplateClipPlan($lengthMs, $effect, $transitionOut)';
}

/// One plan per picked item. [sourceMs] is each item's own length (null
/// for photos, which take the full slot). A video shorter than its slot
/// keeps its own length.
List<TemplateClipPlan> planTemplateClips(VideoTemplate t, List<int?> sourceMs) {
  if (t.isBeatSynced) return _planOnBeats(t, sourceMs);
  return [
    for (var i = 0; i < sourceMs.length; i++)
      TemplateClipPlan(
        sourceMs[i] == null ? t.slotsMs[i % t.slotsMs.length] : _min(sourceMs[i]!, t.slotsMs[i % t.slotsMs.length]),
        t.effects.isEmpty ? null : t.effects[i % t.effects.length],
        i == sourceMs.length - 1 ? 'cut' : t.transition,
      ),
  ];
}

/// Beat-synced plan: every clip ends on a beat, counted from the start of
/// the song. A video shorter than its slot is cut to the most whole beats
/// it can fill (only a video shorter than one beat can't stay on the grid).
List<TemplateClipPlan> _planOnBeats(VideoTemplate t, List<int?> sourceMs) {
  final beatMs = t.beatMs;
  final slots = t.beats!;
  final out = <TemplateClipPlan>[];
  var cursor = 0; // timeline position in ms
  for (var i = 0; i < sourceMs.length; i++) {
    // Start from the beat at (or just after) the cursor — a too-short clip
    // may have left it between beats — and end `slots[i]` beats later.
    final startBeat = (cursor / beatMs - 1e-6).ceil();
    var length = ((startBeat + slots[i % slots.length]) * beatMs).round() - cursor;
    final src = sourceMs[i];
    if (src != null && src < length) {
      // Shorter video: end on the last beat it still reaches, or use all of
      // it when no beat falls inside it.
      final lastBeat = ((cursor + src) / beatMs + 1e-6).floor();
      final onBeat = (lastBeat * beatMs).round() - cursor;
      length = onBeat > 0 && onBeat <= src ? onBeat : src;
    }
    cursor += length;
    out.add(TemplateClipPlan(
      length,
      t.effects.isEmpty ? null : t.effects[i % t.effects.length],
      i == sourceMs.length - 1 ? 'cut' : t.transition,
    ));
  }
  return out;
}

int _min(int a, int b) => a < b ? a : b;

/// Template titles placed on a video [totalMs] long: negative times count
/// back from the end; anything that would start past the end, or end up
/// shorter than 300 ms, is dropped.
List<(TemplateText, int, int)> placeTemplateTexts(VideoTemplate t, int totalMs) {
  final out = <(TemplateText, int, int)>[];
  for (final x in t.texts) {
    var s = x.startMs < 0 ? totalMs + x.startMs : x.startMs;
    var e = x.endMs < 0 ? totalMs + x.endMs : x.endMs;
    if (s < 0) s = 0;
    if (e > totalMs) e = totalMs;
    if (e - s < 300) continue;
    out.add((x, s, e));
  }
  return out;
}
