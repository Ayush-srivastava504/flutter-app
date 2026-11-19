import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/assistant_executor.dart';
import '../ai/assistant_providers.dart';
import '../ai/command_planner.dart';
import '../ai/edit_action.dart';
import '../ai/gen/ai_provider.dart';
import '../ai/gen/generation_service.dart';
import '../app/app_theme.dart';
import '../data/database_provider.dart';
import '../history/project_history.dart';
import '../models/media_asset.dart';
import '../providers/timeline_providers.dart';
import '../router/app_router.dart';
import '../services/analytics_service.dart';
import '../services/media_import_service.dart';

enum AssistantTab { edit, create }

/// Opens the assistant.
///  * **Edit** — type what you want ("trim the first 2 seconds and make it
///    black and white") or tap a smart tool. Everything it does is a normal
///    edit, so undo reverses it. Works offline.
///  * **Create with AI** — generate an image or video with the user's own
///    API key (OpenAI / Gemini / Replicate) and drop it on the timeline via
///    [onGenerated].
Future<void> showAssistantSheet(
  BuildContext context,
  String projectId, {
  Future<void> Function(MediaAsset asset)? onGenerated,
  AssistantTab initialTab = AssistantTab.edit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) => Padding(
      // Keep the text field above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: AssistantSheet(projectId: projectId, onGenerated: onGenerated, initialTab: initialTab),
    ),
  );
}

/// Runs [actions] through the assistant executor with the editor's current
/// selection and playhead. Shared by the assistant sheet and the YouTube
/// Studio Pro toolkit, so both go through the same undoable path.
Future<List<ActionResult>> runEditActions(WidgetRef ref, String projectId, List<EditAction> actions) {
  final history = ref.read(projectHistoryProvider(projectId));
  final executor = AssistantExecutor(
    ref.read(projectDatabaseProvider),
    analyzer: ref.read(mediaAnalyzerProvider),
    onUndo: history.undo,
    onRedo: history.redo,
  );
  return executor.run(
    actions,
    AssistantContext(
      projectId: projectId,
      selectedClipId: ref.read(selectedClipIdProvider),
      playheadMs: ref.read(playheadMsProvider),
    ),
  );
}

class AssistantSheet extends ConsumerStatefulWidget {
  final String projectId;
  final Future<void> Function(MediaAsset asset)? onGenerated;
  final AssistantTab initialTab;
  const AssistantSheet({super.key, required this.projectId, this.onGenerated, this.initialTab = AssistantTab.edit});

  @override
  ConsumerState<AssistantSheet> createState() => _AssistantSheetState();
}

class _AssistantSheetState extends ConsumerState<AssistantSheet> {
  late AssistantTab _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: (media.size.height - media.viewInsets.bottom) * 0.86),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(tab: _tab),
              const SizedBox(height: 12),
              _TabSwitch(tab: _tab, onChanged: (t) => setState(() => _tab = t)),
              const SizedBox(height: 12),
              Flexible(
                child: _tab == AssistantTab.edit
                    ? _EditPanel(projectId: widget.projectId)
                    : _CreatePanel(projectId: widget.projectId, onGenerated: widget.onGenerated),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AssistantTab tab;
  const _Header({required this.tab});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.ember, AppColors.pro]),
          ),
          child: const Icon(Icons.auto_awesome, color: AppColors.ink, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Assistant', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text(
              tab == AssistantTab.edit
                  ? 'Edits your project · works offline · undo anytime'
                  : 'New images & videos with your own AI key',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
          ]),
        ),
        IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded, color: AppColors.textDim),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ]);
}

class _TabSwitch extends StatelessWidget {
  final AssistantTab tab;
  final ValueChanged<AssistantTab> onChanged;
  const _TabSwitch({required this.tab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget seg(AssistantTab t, IconData icon, String label) {
      final on = t == tab;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: on ? AppColors.surfaceTop : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 17, color: on ? AppColors.ember : AppColors.textDim),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, color: on ? AppColors.text : AppColors.textDim)),
              ),
            ]),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(15)),
      child: Row(children: [
        seg(AssistantTab.edit, Icons.tune_rounded, 'Edit'),
        seg(AssistantTab.create, Icons.auto_awesome, 'Create with AI'),
      ]),
    );
  }
}

// ---- Edit -------------------------------------------------------------------

class _EditPanel extends ConsumerStatefulWidget {
  final String projectId;
  const _EditPanel({required this.projectId});

  @override
  ConsumerState<_EditPanel> createState() => _EditPanelState();
}

class _EditPanelState extends ConsumerState<_EditPanel> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_Msg> _log = [];
  bool _busy = false;

  static const List<(SmartTool, IconData, String, String)> _tools = [
    (SmartTool.autoPolish, Icons.auto_fix_high, 'Auto polish', 'Dissolves, music fades and ducking'),
    (SmartTool.removeSilences, Icons.graphic_eq, 'Remove silences', 'Cuts the quiet parts out'),
    (SmartTool.splitScenes, Icons.movie_filter_outlined, 'Split scenes', 'Cuts where the picture changes'),
    (SmartTool.balanceLoudness, Icons.equalizer, 'Balance loudness', 'Evens out volume between clips'),
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _submit(String request) async {
    final text = request.trim();
    if (text.isEmpty || _busy) return;
    _input.clear();
    _add(_Msg.user(text));
    setState(() => _busy = true);
    try {
      final plan = await ref.read(assistantPlannerProvider).plan(text);
      if (plan.isEmpty) {
        _add(const _Msg.reply(false, "I didn't understand that. Try one of the suggestions above the text box."));
        return;
      }
      await _run(plan.actions);
      for (final part in plan.unrecognized) {
        _add(_Msg.reply(false, 'Not understood: "$part"'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runTool(SmartTool tool) async {
    if (_busy) return;
    final scope = tool == SmartTool.autoPolish || tool == SmartTool.balanceLoudness
        ? const ClipScope.all()
        : const ClipScope.selected();
    final action = RunSmartTool(tool, scope);
    _add(_Msg.user(action.describe()));
    setState(() => _busy = true);
    try {
      await _run([action]);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _run(List<EditAction> actions) async {
    final results = await runEditActions(ref, widget.projectId, actions);
    for (final r in results) {
      _add(_Msg.reply(r.ok, r.message));
    }
  }

  Future<void> _undo() async {
    await ref.read(projectHistoryProvider(widget.projectId)).undo();
    _add(const _Msg.reply(true, 'Undone.'));
  }

  void _add(_Msg m) {
    if (!mounted) return;
    setState(() => _log.add(m));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lastOk = _log.lastIndexWhere((m) => !m.isUser && m.ok && m.text != 'Undone.');
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Flexible(
        child: ListView(
          controller: _scroll,
          shrinkWrap: true,
          children: [
            if (_log.isEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Smart tools', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDim)),
              ),
              LayoutBuilder(builder: (context, box) {
                final w = (box.maxWidth - 10) / 2;
                return Wrap(spacing: 10, runSpacing: 10, children: [
                  for (final (tool, icon, title, subtitle) in _tools)
                    SizedBox(
                      width: w,
                      child: _ToolCard(
                        icon: icon,
                        title: title,
                        subtitle: subtitle,
                        onTap: _busy ? null : () => _runTool(tool),
                      ),
                    ),
                ]);
              }),
            ] else
              for (var i = 0; i < _log.length; i++)
                _Bubble(msg: _log[i], onUndo: i == lastOk && !_busy ? _undo : null),
            if (_busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('Working…', style: TextStyle(color: AppColors.textDim)),
                ]),
              ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: assistantExamples.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, i) => ActionChip(
            visualDensity: VisualDensity.compact,
            label: Text(assistantExamples[i], style: const TextStyle(fontSize: 12)),
            onPressed: _busy ? null : () => _submit(assistantExamples[i]),
          ),
        ),
      ),
      const SizedBox(height: 8),
      _InputPill(
        controller: _input,
        enabled: !_busy,
        hint: 'Tell me an edit — e.g. speed up 2x and mute',
        onSend: () => _submit(_input.text),
      ),
    ]);
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _ToolCard({required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.ember.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: AppColors.ember),
              ),
              const SizedBox(height: 10),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textDim, fontSize: 11.5, height: 1.25)),
            ]),
          ),
        ),
      );
}

class _Msg {
  final bool isUser;
  final bool ok;
  final String text;
  const _Msg.user(this.text)
      : isUser = true,
        ok = true;
  const _Msg.reply(this.ok, this.text) : isUser = false;
}

class _Bubble extends StatelessWidget {
  final _Msg msg;
  final VoidCallback? onUndo;
  const _Bubble({required this.msg, this.onUndo});

  @override
  Widget build(BuildContext context) {
    final user = msg.isUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
          decoration: BoxDecoration(
            color: user ? AppColors.ember.withValues(alpha: 0.18) : AppColors.surfaceHigh,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(user ? 16 : 4),
              bottomRight: Radius.circular(user ? 4 : 16),
            ),
          ),
          child: user
              ? Text(msg.text, style: const TextStyle(fontWeight: FontWeight.w600))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(msg.ok ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          size: 16, color: msg.ok ? AppColors.ok : AppColors.warn),
                    ),
                    const SizedBox(width: 8),
                    Flexible(child: Text(msg.text, style: const TextStyle(color: AppColors.text))),
                  ]),
                  if (onUndo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: GestureDetector(
                        onTap: onUndo,
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.undo_rounded, size: 15, color: AppColors.ember),
                          SizedBox(width: 4),
                          Text('Undo', style: TextStyle(color: AppColors.ember, fontWeight: FontWeight.w700, fontSize: 12.5)),
                        ]),
                      ),
                    ),
                ]),
        ),
      ),
    );
  }
}

class _InputPill extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String hint;
  final VoidCallback onSend;
  const _InputPill({
    required this.controller,
    required this.enabled,
    required this.hint,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 13.5),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          IconButton.filled(
              tooltip: 'Run',
              style: IconButton.styleFrom(backgroundColor: AppColors.ember, foregroundColor: AppColors.ink),
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
        ]),
      );
}

// ---- Create with AI -----------------------------------------------------------

class _CreatePanel extends ConsumerStatefulWidget {
  final String projectId;
  final Future<void> Function(MediaAsset asset)? onGenerated;
  const _CreatePanel({required this.projectId, this.onGenerated});

  @override
  ConsumerState<_CreatePanel> createState() => _CreatePanelState();
}

enum _Phase { idle, running, done, failed }

class _CreatePanelState extends ConsumerState<_CreatePanel> {
  final TextEditingController _prompt = TextEditingController();
  GenKind _kind = GenKind.image;
  List<AiProvider>? _ready; // null while loading
  AiProvider? _provider;
  String? _model;
  final Set<String> _styles = {};
  int _seconds = 6;

  _Phase _phase = _Phase.idle;
  String _status = '';
  String? _error;
  String? _resultPath;
  GenerationJob? _job;
  Timer? _ticker;
  int _elapsed = 0;

  static const _styleOptions = ['Cinematic', 'Photoreal', 'Anime', '3D render', 'Watercolor', 'Neon', 'Vintage film'];
  static const _durations = [4, 6, 8, 10];

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _job?.cancel();
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    final store = ref.read(aiKeyStoreProvider);
    final ready = await store.ready(_kind);
    final provider = ready.contains(_provider) ? _provider : ready.firstOrNull;
    final model = provider == null ? null : await store.model(provider, _kind);
    if (!mounted) return;
    setState(() {
      _ready = ready;
      _provider = provider;
      _model = model;
    });
  }

  Future<void> _pickProvider(AiProvider p) async {
    final model = await ref.read(aiKeyStoreProvider).model(p, _kind);
    if (mounted) {
      setState(() {
        _provider = p;
        _model = model;
      });
    }
  }

  void _setKind(GenKind k) {
    if (k == _kind || _phase == _Phase.running) return;
    setState(() {
      _kind = k;
      _ready = null;
    });
    _loadProviders();
  }

  Future<void> _openKeys() async {
    await Navigator.of(context).pushNamed(AppRouter.settings);
    if (mounted) _loadProviders();
  }

  String get _fullPrompt {
    final base = _prompt.text.trim();
    if (_styles.isEmpty || base.isEmpty) return base;
    return '$base. Style: ${_styles.join(', ').toLowerCase()}.';
  }

  Future<void> _generate() async {
    final provider = _provider;
    if (provider == null || _phase == _Phase.running) return;
    FocusScope.of(context).unfocus();
    final aspect = ref.read(projectProvider(widget.projectId)).value?.aspectRatio ?? 9 / 16;
    final job = GenerationJob(ref.read(aiKeyStoreProvider));
    setState(() {
      _job = job;
      _phase = _Phase.running;
      _status = 'Sending to ${provider.label}…';
      _error = null;
      _elapsed = 0;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
    try {
      final path = await job.run(
        provider,
        GenRequest(prompt: _fullPrompt, kind: _kind, aspect: aspect, durationSec: _seconds),
        onStatus: (s) {
          if (mounted) setState(() => _status = s);
        },
      );
      if (mounted) setState(() => _status = 'Adding to your timeline…');
      final asset = await MediaImportService().assetFromFile(path);
      await widget.onGenerated?.call(asset);
      Analytics.instance.log('ai_generate', {'provider': provider.name, 'kind': _kind.name, 'ok': 1});
      if (!mounted) return;
      setState(() {
        _resultPath = path;
        _phase = _Phase.done;
      });
    } catch (e) {
      Analytics.instance.log('ai_generate', {'provider': provider.name, 'kind': _kind.name, 'ok': 0});
      if (!mounted) return;
      setState(() {
        _error = e is GenerationException ? e.message : 'Something went wrong: $e';
        _phase = _Phase.failed;
      });
    } finally {
      _ticker?.cancel();
      _job = null;
    }
  }

  void _cancel() {
    _job?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _ready;
    return ListView(shrinkWrap: true, children: [
      Row(children: [
        Expanded(
          child: _KindCard(
            icon: Icons.image_outlined,
            title: 'Image',
            subtitle: 'Adds a photo clip',
            selected: _kind == GenKind.image,
            onTap: () => _setKind(GenKind.image),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KindCard(
            icon: Icons.movie_creation_outlined,
            title: 'Video',
            subtitle: 'Adds a video clip',
            selected: _kind == GenKind.video,
            onTap: () => _setKind(GenKind.video),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      if (ready == null)
        const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
      else if (ready.isEmpty)
        _NoKeyCard(kind: _kind, onOpen: _openKeys)
      else ...[
        if (_phase == _Phase.running)
          _ProgressCard(status: _status, elapsed: _elapsed, onCancel: _cancel)
        else if (_phase == _Phase.done && _resultPath != null)
          _DoneCard(path: _resultPath!, kind: _kind, onAnother: () => setState(() => _phase = _Phase.idle))
        else ...[
          if (_phase == _Phase.failed && _error != null) ...[
            _ErrorCard(message: _error!),
            const SizedBox(height: 10),
          ],
          Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            for (final p in ready)
              ChoiceChip(
                label: Text(p.label),
                selected: p == _provider,
                onSelected: (_) => _pickProvider(p),
              ),
            TextButton(onPressed: _openKeys, child: const Text('Keys…')),
          ]),
          if (_model != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Text('Model: $_model', style: const TextStyle(color: AppColors.textFaint, fontSize: 11.5)),
            ),
          TextField(
            controller: _prompt,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: _kind == GenKind.image
                  ? 'Describe the picture — e.g. a cosy café at golden hour, rain on the window'
                  : 'Describe the shot — e.g. slow aerial flight over a neon city at night',
              hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 13.5),
              filled: true,
              fillColor: AppColors.surfaceHigh,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          const Text('Style', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDim, fontSize: 12.5)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final s in _styleOptions)
              FilterChip(
                visualDensity: VisualDensity.compact,
                label: Text(s, style: const TextStyle(fontSize: 12)),
                selected: _styles.contains(s),
                onSelected: (on) => setState(() => on ? _styles.add(s) : _styles.remove(s)),
              ),
          ]),
          if (_kind == GenKind.video) ...[
            const SizedBox(height: 12),
            const Text('Length', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDim, fontSize: 12.5)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              for (final d in _durations)
                ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  label: Text('$d s'),
                  selected: _seconds == d,
                  onSelected: (_) => setState(() => _seconds = d),
                ),
            ]),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _prompt.text.trim().isEmpty || _provider == null ? null : _generate,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: Text(_kind == GenKind.image ? 'Generate image' : 'Generate video'),
          ),
          const SizedBox(height: 6),
          Text(
            'Uses your ${_provider?.label ?? ''} account — they bill you, not Cliper. '
            'Fits your project\'s frame shape and lands at the end of the timeline.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textFaint, fontSize: 11),
          ),
        ],
      ],
    ]);
  }
}

class _KindCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _KindCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? AppColors.ember.withValues(alpha: 0.14) : AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? AppColors.ember : Colors.transparent, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(icon, color: selected ? AppColors.ember : AppColors.textDim),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textDim, fontSize: 11.5)),
                ]),
              ),
            ]),
          ),
        ),
      );
}

class _NoKeyCard extends StatelessWidget {
  final GenKind kind;
  final VoidCallback onOpen;
  const _NoKeyCard({required this.kind, required this.onOpen});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          const Icon(Icons.key_rounded, color: AppColors.pro, size: 28),
          const SizedBox(height: 8),
          const Text('Add an API key to start', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            kind == GenKind.image
                ? 'Use your own OpenAI, Google Gemini or Replicate account. Your key stays on this phone.'
                : 'Videos need a Google Gemini or Replicate key. Your key stays on this phone.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textDim, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: onOpen, icon: const Icon(Icons.key, size: 18), label: const Text('Open AI keys')),
        ]),
      );
}

class _ProgressCard extends StatelessWidget {
  final String status;
  final int elapsed;
  final VoidCallback onCancel;
  const _ProgressCard({required this.status, required this.elapsed, required this.onCancel});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
          const SizedBox(height: 12),
          Text(status, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${elapsed ~/ 60}:${(elapsed % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(color: AppColors.textDim, fontFeatures: [FontFeature.tabularFigures()])),
          const SizedBox(height: 8),
          TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ]),
      );
}

class _DoneCard extends StatelessWidget {
  final String path;
  final GenKind kind;
  final VoidCallback onAnother;
  const _DoneCard({required this.path, required this.kind, required this.onAnother});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              child: kind == GenKind.image
                  ? Image.file(File(path), fit: BoxFit.contain, cacheWidth: 720)
                  : const ColoredBox(
                      color: AppColors.canvas,
                      child: Center(child: Icon(Icons.movie_rounded, size: 48, color: AppColors.textDim)),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.check_circle_rounded, color: AppColors.ok, size: 18),
            SizedBox(width: 6),
            Flexible(child: Text('Added to the end of your timeline', style: TextStyle(fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: onAnother, icon: const Icon(Icons.refresh, size: 18), label: const Text('Make another')),
        ]),
      );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.youtube.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.youtube.withValues(alpha: 0.4)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline, color: AppColors.youtube, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.text, fontSize: 13))),
        ]),
      );
}
