/// F15: how a clip whose shape differs from the project's frame fills it.
///
/// Preview does: `fit` letterboxes, `fill` crops to cover, `blur` shows the
/// same letterboxed picture as `fit` (a second blurred video texture per
/// frame is too costly for the live preview).
/// Export does: the real thing for all three, including the blurred
/// background (see `fitFilters` in `export_command_builder.dart`).
library fit_mode_x;

class FitMode {
  final String id;
  final String label;
  const FitMode(this.id, this.label);
}

const String fitModeFit = 'fit';
const String fitModeFill = 'fill';
const String fitModeBlur = 'blur';

const List<FitMode> fitModes = [
  FitMode(fitModeFit, 'Fit'),
  FitMode(fitModeFill, 'Fill'),
  FitMode(fitModeBlur, 'Blur'),
];

/// Unknown or legacy values behave as `fit`, so a bad row can never break
/// the preview or the export.
String normalizeFitMode(String? id) =>
    id == fitModeFill || id == fitModeBlur ? id! : fitModeFit;
