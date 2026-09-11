# Video Editor App — Phase 2 Scaffold

This is a hand-written scaffold matching what `flutter create` + Phase 2 wiring
would produce. It was built without a Flutter SDK available (this environment
can't reach pub.dev), so a few one-time setup steps are needed on your machine.

## Setup (run locally)

1. Turn this into a real Flutter project shell (generates `android/`, `ios/`,
   platform files) without touching the `lib/` you already have:
   ```bash
   flutter create --project-name video_editor_app --org com.yourcompany .
   ```
   Flutter will skip files that already exist (`lib/`, `pubspec.yaml`), so
   nothing here gets overwritten — it only fills in the missing native folders.

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate the Drift database code. This produces `project_database.g.dart`
   and, as of Phase 6, `test/support/legacy_v3_database.g.dart` too —
   build_runner picks up any `@DriftDatabase`-annotated class in the
   package, not just ones under `lib/`:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Merge permissions:
   - Copy the entries in `android_manifest_permissions.xml` into
     `android/app/src/main/AndroidManifest.xml`.
   - Copy the keys in `ios_info_plist_permissions.xml` into
     `ios/Runner/Info.plist`.

5. Run it:
   ```bash
   flutter run
   ```

6. Run the tests (Phase 6 adds the project's first ones):
   ```bash
   flutter test
   ```

## What's built (Phase 2)

- Navigation: Home/Projects → Editor → Export (`lib/router/app_router.dart`)
- Permission request flow (`lib/services/permission_service.dart`)
- Local project data model + persistence via Drift/SQLite
  (`lib/data/project_database.dart`): Projects, Clips, AudioTracks,
  TextOverlays — all non-destructive, edit metadata only
- Home screen: create/list projects
- Editor & Export screens: layout scaffolds with clearly marked placeholders
  for Phase 3–8 work

## What's next (Phase 3)

- Media picker screen (image_picker/file_picker) wired into the Editor
- Preview player component (video_player) for a single imported clip
- Thumbnail generation/caching (video_thumbnail)
- Metadata normalization (duration, resolution, orientation)

## Notes

- FFmpeg (`ffmpeg_kit_flutter`) is in `pubspec.yaml` but not wired to
  anything yet — it's reserved for the Phase 8 export pipeline only.
  Preview playback in the Editor uses `video_player`, not FFmpeg.
- All edit operations (trim, order, transitions, filters) are stored as
  metadata on `Clips`/`AudioTracks`/`TextOverlays` — original media files
  are never modified, per the non-destructive editing requirement.
