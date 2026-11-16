import 'package:path/path.dart' as p;

/// The `Clips` table doesn't store a media type, so photo-vs-video is
/// inferred from the source file's extension everywhere (timeline maths,
/// preview, export). This is the one definition of that rule.
const Set<String> photoExtensions = {'.jpg', '.jpeg', '.png', '.heic', '.webp', '.gif'};

bool isPhotoPath(String path) => photoExtensions.contains(p.extension(path).toLowerCase());
