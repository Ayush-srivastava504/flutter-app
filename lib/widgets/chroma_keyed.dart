import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/chroma_key.dart';
import 'shader_programs.dart';

/// Preview of background removal: [child] colour-keyed by `shaders/key.frag`
/// and laid over the new background (colour or photo). Without shader
/// support (no Impeller) the clip is shown unkeyed — the export still keys.
class ChromaKeyed extends StatefulWidget {
  final ChromaKeySpec? spec;
  final Widget child;
  const ChromaKeyed({super.key, required this.spec, required this.child});

  @override
  State<ChromaKeyed> createState() => _ChromaKeyedState();
}

class _ChromaKeyedState extends State<ChromaKeyed> {
  ui.FragmentProgram? _program;

  @override
  void initState() {
    super.initState();
    ShaderPrograms.key().then((p) {
      if (mounted && p != null) setState(() => _program = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final program = _program;
    final Widget background;
    if (spec == null || program == null) {
      background = const SizedBox.shrink();
    } else if (spec.usesImage) {
      background = Image.file(File(spec.bgImage!), fit: BoxFit.cover, cacheWidth: 1080,
          errorBuilder: (_, __, ___) => ColoredBox(color: Color(0xFF000000 | spec.bgColor)));
    } else {
      background = ColoredBox(color: Color(0xFF000000 | spec.bgColor));
    }
    final filter = spec == null || program == null ? null : ui.ImageFilter.shader(configureKeyShader(program, spec));
    return Stack(fit: StackFit.expand, children: [
      background,
      filter == null ? widget.child : ImageFiltered(imageFilter: filter, child: widget.child),
    ]);
  }
}
