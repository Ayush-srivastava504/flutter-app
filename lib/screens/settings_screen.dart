import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/gen/ai_key_store.dart';
import '../ai/gen/ai_provider.dart';
import '../ai/gen/generation_service.dart';
import '../app/launch_gate.dart' show appPrefsProvider;
import '../app/app_theme.dart';
import '../services/analytics_service.dart';
import '../widgets/common/ui_kit.dart';

/// Settings: AI keys (bring your own), privacy (analytics opt-out), about.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          const SectionHeader('AI keys'),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
              'Generate images and videos with your own account. Your key is stored encrypted on this phone, '
              'and requests go straight from your phone to the provider — ClipForge has no server and never sees '
              'your prompts. The provider bills you for what you generate.',
              style: TextStyle(color: AppColors.textDim, fontSize: 12.5, height: 1.35),
            ),
          ),
          for (final p in AiProvider.values) ...[
            _ProviderCard(provider: p, store: ref.read(aiKeyStoreProvider)),
            const SizedBox(height: 12),
          ],
          const SectionHeader('Privacy'),
          const _AnalyticsTile(),
          const SectionHeader('About'),
          TapCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            onTap: () {
              registerNativeLicences();
              showLicensePage(context: context, applicationName: 'ClipForge');
            },
            child: const Row(children: [
              Icon(Icons.description_outlined, color: AppColors.textDim),
              SizedBox(width: 12),
              Expanded(child: Text('Open-source licences', style: TextStyle(fontWeight: FontWeight.w600))),
              Icon(Icons.chevron_right_rounded, color: AppColors.textFaint),
            ]),
          ),
        ],
      ),
    );
  }
}

bool _licencesAdded = false;

/// Flutter lists Dart packages itself; the native FFmpeg libraries inside
/// FFmpegKit must be added by hand (LGPL — `docs/LAUNCH_CHECKLIST.md` L9).
void registerNativeLicences() {
  if (_licencesAdded) return;
  _licencesAdded = true;
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(['FFmpeg (via ffmpeg_kit_flutter_new_full)'], '''
This app uses libraries from the FFmpeg project under the GNU Lesser General Public License v3.0 (LGPL-3.0).
FFmpeg is a trademark of Fabrice Bellard. Source code: https://ffmpeg.org
License text: https://www.gnu.org/licenses/lgpl-3.0.html''');
  });
}

class _AnalyticsTile extends ConsumerStatefulWidget {
  const _AnalyticsTile();

  @override
  ConsumerState<_AnalyticsTile> createState() => _AnalyticsTileState();
}

class _AnalyticsTileState extends ConsumerState<_AnalyticsTile> {
  bool? _on;

  @override
  void initState() {
    super.initState();
    ref.read(appPrefsProvider).analyticsEnabled.then((v) {
      if (mounted) setState(() => _on = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final configured = Analytics.instance.available;
    return TapCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(children: [
        const Icon(Icons.insights_outlined, color: AppColors.textDim),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Share usage & crash reports', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              configured
                  ? 'Anonymous: which features are used and why the app crashed. Never your videos, photos or prompts.'
                  : 'Not active in this build.',
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
          ]),
        ),
        Switch(
          value: _on ?? true,
          onChanged: _on == null
              ? null
              : (v) async {
                  setState(() => _on = v);
                  await ref.read(appPrefsProvider).setAnalyticsEnabled(v);
                  await Analytics.instance.setEnabled(v);
                },
        ),
      ]),
    );
  }
}

class _ProviderCard extends StatefulWidget {
  final AiProvider provider;
  final AiKeyStore store;
  const _ProviderCard({required this.provider, required this.store});

  @override
  State<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<_ProviderCard> {
  final _key = TextEditingController();
  final _imageModel = TextEditingController();
  final _videoModel = TextEditingController();
  bool _hasKey = false;
  bool _editing = false;
  bool _obscure = true;
  bool _showModels = false;

  AiProvider get p => widget.provider;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final k = await widget.store.key(p);
    final im = await widget.store.modelOverride(p, GenKind.image);
    final vm = await widget.store.modelOverride(p, GenKind.video);
    if (!mounted) return;
    setState(() {
      _hasKey = k != null && k.isNotEmpty;
      _imageModel.text = im ?? '';
      _videoModel.text = vm ?? '';
    });
  }

  @override
  void dispose() {
    _key.dispose();
    _imageModel.dispose();
    _videoModel.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    final v = _key.text.trim();
    if (v.isEmpty) return;
    await widget.store.setKey(p, v);
    _key.clear();
    if (!mounted) return;
    setState(() {
      _hasKey = true;
      _editing = false;
    });
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.label} key saved on this phone.')));
  }

  Future<void> _removeKey() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove your ${p.label} key?'),
        content: const Text('You can add it again any time.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    await widget.store.setKey(p, null);
    if (mounted) setState(() => _hasKey = false);
  }

  Future<void> _saveModels() async {
    await widget.store.setModelOverride(p, GenKind.image, _imageModel.text);
    if (p.supports(GenKind.video)) await widget.store.setModelOverride(p, GenKind.video, _videoModel.text);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Models saved.')));
  }

  @override
  Widget build(BuildContext context) {
    final caps = [
      'Images',
      if (p.supports(GenKind.video)) 'Videos',
    ].join(' + ');
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: _hasKey ? AppColors.ok.withValues(alpha: 0.4) : AppColors.line),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 2),
              Text(caps, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
            ]),
          ),
          _StatusPill(on: _hasKey),
        ]),
        const SizedBox(height: 10),
        if (_hasKey && !_editing)
          Row(children: [
            const Expanded(
              child: Text('••••••••••••  saved', style: TextStyle(color: AppColors.textDim, letterSpacing: 1)),
            ),
            TextButton(onPressed: () => setState(() => _editing = true), child: const Text('Replace')),
            TextButton(onPressed: _removeKey, child: const Text('Remove')),
          ])
        else ...[
          TextField(
            controller: _key,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              hintText: 'Paste your key (${p.keyHint})',
              isDense: true,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Show' : 'Hide',
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => _saveKey(),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: 'https://${p.keyUrl}'));
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Link copied — open it in your browser.')));
                },
                child: Text('Get a key: ${p.keyUrl}',
                    style: const TextStyle(color: AppColors.ember, fontSize: 12, decoration: TextDecoration.underline)),
              ),
            ),
            if (_editing) TextButton(onPressed: () => setState(() => _editing = false), child: const Text('Cancel')),
            FilledButton(onPressed: _saveKey, child: const Text('Save')),
          ]),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _showModels = !_showModels),
            icon: Icon(_showModels ? Icons.expand_less : Icons.tune, size: 18),
            label: const Text('Models (advanced)'),
          ),
        ),
        if (_showModels) ...[
          TextField(
            controller: _imageModel,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Image model',
              hintText: p.defaultImageModel,
              helperText: 'Empty = ${p.defaultImageModel}',
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
          if (p.supports(GenKind.video)) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _videoModel,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Video model',
                hintText: p.defaultVideoModel,
                helperText: 'Empty = ${p.defaultVideoModel}',
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: _saveModels, child: const Text('Save models')),
          ),
        ],
      ]),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool on;
  const _StatusPill({required this.on});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (on ? AppColors.ok : AppColors.textFaint).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(on ? Icons.check_circle : Icons.radio_button_unchecked, size: 13, color: on ? AppColors.ok : AppColors.textFaint),
          const SizedBox(width: 4),
          Text(on ? 'Ready' : 'No key',
              style: TextStyle(color: on ? AppColors.ok : AppColors.textDim, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      );
}
