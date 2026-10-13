# ClipForge — Google Play launch checklist

Written 2026-10-11 from the repo + Google's current policy pages (sources at the end). Items marked ✅ are facts I checked; ⚠️ means "check it yourself — I could not". Play rules change: if the Console disagrees with this file, **the Console wins**.

## 0. Can you really "launch today"?
| Your situation | What is possible today |
|---|---|
| **Personal** developer account created **after 2023-11-13** | You **cannot** publish to Production yet. Google requires a **closed test with ≥ 12 testers opted in continuously for 14 days**, then a production-access application (✅ Play Help, "App testing requirements for new personal developer accounts"). Today you can upload to **Internal testing** (and start the 14-day closed-test clock). Recruit 15–20 testers, not exactly 12. |
| Personal account created **before** 2023-11-13 | Production is possible after the app passes review. |
| **Organisation** account | The 12-tester rule applies to personal accounts only (✅ Play Help); production is possible after review. Organisation verification can itself take time. |
You decide this in Play Console → account details (FACTS U-06). **If you cannot tell, assume the 14-day rule applies** and plan: today = internal + closed test; production in ~2–3 weeks.

## 1. Blockers — fix before uploading anything
| # | Blocker | Why (evidence) | Fix |
|---|---|---|---|
| L1 | **Release is debug-signed** | `build.gradle.kts` release block (FACTS F-06) | Create an upload keystore + `android/key.properties`, wire `signingConfigs` (§1.1). Enrol in **Play App Signing** at first upload. |
| L2 | **Target API must be 36** for new apps/updates | Play Help: new apps and updates must target Android 16 (API 36) since 2026-08-31 ✅. Repo's `targetSdk` comes from your Flutter SDK (F-04) ⚠️ | Set `targetSdk = 36` (and `compileSdk = 36`) explicitly (§1.2); verify in the built bundle (§3). |
| L3 | **Unneeded sensitive permissions** | `READ_MEDIA_VIDEO/IMAGES` are *restricted* — Play wants a system photo picker unless broad media access is core (✅ Play Help "Photo and Video Permissions"). The app already imports via `image_picker` (F-23). `RECORD_AUDIO` has no feature (F-22). All are prompted at launch (F-21). | Remove them from the manifest and stop requesting them at launch (§1.3). Then run `TESTING.md` scenario B9. |
| L4 | **16 KB page-size support** for native libs | Play requires apps targeting Android 15+ to support 16 KB pages; Console warns about **2027-02-01** for updates (✅ developer.android.com). FFmpegKit 2.5.7 alignment is **unknown** (U-03) ⚠️ | `bash tools/check_16kb.sh app-release.aab` → must say `ALL OK`. If FAIL: you need a FFmpegKit build with 16 KB alignment (new version of the package or a fork with an acceptable LGPL licence) — **do not swap packages on launch day without a full export test.** Not a day-1 upload blocker per the Console date, but Google states apps without 16 KB support won't work on 16 KB devices in future Android releases. |
| L5 | **Release build never tested** | R8/shrinking can strip native-plugin classes (U-02) | Install the **release** build on a phone and export (`TESTING.md` R1, X1–X2). |
| L6 | **Export never confirmed on a real phone** | `APP_GUIDE.md` §8/§12; FACTS U-01 | Run `TESTING.md` section D. If X1 fails, do **not** launch — a video editor that can't export is the whole product. |
| L7 | **Privacy policy URL** required | Play Console requires it for the store listing | Fill `docs/legal/PRIVACY_POLICY_TEMPLATE.md`, host it on a public URL (a page on a site you control). |
| L8 | **Audio-loop licence unknown** | F-81 | Confirm you created the 3 WAV loops or have a licence permitting commercial redistribution; otherwise remove them (`assets/audio/`, `bundled_track.dart`). |
| L9 | **LGPL notice for FFmpeg** | FFmpegKit is LGPL-3.0 (F-83) | Show the licence/notice in-app (Settings/About or `showLicensePage`) and publish `docs/legal/THIRD_PARTY_NOTICES.md`. Flutter's licence page lists Dart packages automatically; **add the FFmpeg/native notices manually**. I am not a lawyer — get legal review if you monetise. |
| L10 | Split-clip bug B-01 (volume resets) | FACTS B-01 | One-line fix + test (copy `volume`, `filterPreset`). Ship-worthy fix. |

### 1.1 Signing (`android/app/build.gradle.kts`) — standard Flutter pattern, **not built here**
Generate the key once and **back it up** (losing it = you can't update the app unless Play App Signing + upload-key reset):
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Create `android/key.properties` (already git-ignored, F-07):
```
storePassword=<fill>
keyPassword=<fill>
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```
In `build.gradle.kts` (top: `import java.util.Properties` and `import java.io.FileInputStream`), inside `android { }`:
```kotlin
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) load(FileInputStream(f))
}
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String?
        keyPassword = keystoreProperties["keyPassword"] as String?
        storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
        storePassword = keystoreProperties["storePassword"] as String?
    }
}
buildTypes { release { signingConfig = signingConfigs.getByName("release") } }
```
Then replace the debug line in the `release` block. (Pattern follows Flutter's "Build and release an Android app" guide — confirm against the current guide for your Flutter version.)

### 1.2 Target API
In `defaultConfig`: `targetSdk = 36`; at the top of `android {}`: `compileSdk = 36`. ⚠️ AGP 8.11.1 / Gradle 8.14.3 (F-05) are expected to support API 36 but I have not built it; if Gradle complains, bump AGP/Gradle together. Then test on Android 16 (`TESTING.md` R5): back-navigation behaviour and edge-to-edge changed for apps targeting 36.

### 1.3 Permissions — target manifest
Keep: `POST_NOTIFICATIONS` (export notification), `WRITE_EXTERNAL_STORAGE maxSdkVersion=28` (gallery save on Android 9 and older — ⚠️ confirm `gal`'s docs), and — until you have tested import on an Android 9–12 phone — `READ_EXTERNAL_STORAGE maxSdkVersion=32`.
Remove: `READ_MEDIA_VIDEO`, `READ_MEDIA_IMAGES`, `READ_MEDIA_AUDIO`, `RECORD_AUDIO`.
Code: delete the `PermissionService.requestMediaPermissions()` call in `HomeScreen.initState` (`home_screen.dart`) — the pickers don't need it. Add `RECORD_AUDIO` back **only** when voice-over (F20) ships, together with the Data-safety/permission declarations.

## 2. Values you must fill in
| # | Value | Where it goes | Today | You provide |
|---|---|---|---|---|
| V1 | Application ID | `build.gradle.kts` | `com.ayushstudio.clipforge` | **Keep, but know it is permanent once published** — can't be changed later |
| V2 | App name (store title ≤ 30 chars) | Play Console → Store listing | — | e.g. `ClipForge: Video Editor` |
| V3 | Launcher label | `AndroidManifest.xml` `android:label` | `clipforge` | `ClipForge` |
| V4 | In-app title | `main.dart` `MaterialApp.title` | `Video Editor` | `ClipForge` |
| V5 | Version | `pubspec.yaml` `version:` | `0.1.0` (no build number) | `1.0.0+1` → name `1.0.0`, code `1`. **Every upload needs a higher `+N`.** |
| V6 | Upload keystore + passwords | `~/upload-keystore.jks`, `android/key.properties` | none | create (§1.1); store a copy + passwords in a password manager |
| V7 | `targetSdk` / `compileSdk` | `build.gradle.kts` | from Flutter SDK | `36` / `36` |
| V8 | Developer account type + 12–20 tester Gmail addresses | Play Console → Closed testing | unknown | personal vs org (U-06); testers' emails |
| V9 | Privacy-policy URL | Console → App content | none | URL of the filled template |
| V10 | Public contact email (+ website optional) | Console → Store listing | none | an email you will actually read |
| V11 | Category | Console | — | Video Players & Editors |
| V12 | Free / paid | Console | — | **Free** (a free app can't be turned into a paid one later) |
| V13 | Countries | Console | — | your choice (all, or a start list) |
| V14 | Short description (≤ 80), full description (≤ 4000) | Store listing | none | write (facts only: offline, local, no account) |
| V15 | Assets: icon 512×512 PNG, feature graphic 1024×500, ≥ 2 phone screenshots | Store listing | `android/…/mipmap-*` launcher icons exist; store assets do not | create; take screenshots from a **release** build; ⚠️ check the Console for current size limits |
| V16 | Target audience / content rating | Console → App content | — | Not designed for children; answer the IARC questionnaire honestly (no UGC hosting, no ads, no gambling) |
| V17 | Release notes (per release) | Release page | — | `1.0.0: first release` |
| V18 | Third-party notices URL / in-app screen | in-app + listing/website | none | from `docs/legal/THIRD_PARTY_NOTICES.md` |
| V19 | Audio-loop licence statement | `THIRD_PARTY_NOTICES.md` | unknown (L8) | "created by me" or the licence |

## 3. Commands — verify the **built** bundle, not the source
```bash
flutter clean && flutter pub get
scripts/dev.sh check                                   # analyze + tests must be green
flutter build appbundle --release                      # → build/app/outputs/bundle/release/app-release.aab

# a) not debug-signed (must NOT say "Android Debug"):
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab | head -20
# b) merged manifest: permissions + target SDK  (bundletool: github.com/google/bundletool)
java -jar bundletool.jar dump manifest --bundle=build/app/outputs/bundle/release/app-release.aab | grep -E "uses-permission|targetSdkVersion|minSdkVersion|versionCode"
# c) 16 KB alignment of native libs
bash tools/check_16kb.sh build/app/outputs/bundle/release/app-release.aab
# d) install a real release build on a phone for testing (universal APK from the bundle, or):
flutter build apk --release --target-platform android-arm64 && adb install -r build/app/outputs/flutter-apk/app-release.apk
```
**Expected in (b):** `targetSdkVersion` 36; **no** `INTERNET`, **no** `READ_MEDIA_*`, **no** `RECORD_AUDIO`; `minSdkVersion` 24. If any plugin added `INTERNET` or another permission, find which (check merged manifest) before filling Data safety.

## 4. Play Console answers (derived from facts — re-check each before submitting)
| Form | Answer | Basis |
|---|---|---|
| App access | All functionality available without login | no accounts in code |
| Ads | **No ads** | F-31 |
| Data safety — collected/shared | **No data collected, none shared** | F-30..F-33: no network permission or network code; processing is on-device ⚠️ re-confirm with the merged manifest (§3-b). Google's definition counts data only if it leaves the device. The user-initiated share sheet is the user's action. |
| Data safety — security practices | Data not transferred off device; no account → no deletion mechanism needed | |
| Privacy policy | URL from V9 | |
| Advertising ID | Not used (no ads SDK) | F-31 |
| Permissions declarations | None required after §1.3. (If you keep `READ_MEDIA_*` you must submit the Photo/Video declaration and justify "core use" — not recommended.) | |
| Foreground service | Not used | F-68 |
| Content rating | IARC questionnaire → expect a low rating, but answer honestly | |
| Target audience | Not "under 13" | |
| Government / financial / health / news | No | |
| Export compliance | Not applicable on Play (no US export form like iOS) — ⚠️ confirm in Console | |

## 5. Upload and test flow
1. Console → Create app (name, default language, app/game = App, free).
2. Fill **App content** (all items in §4) and **Store listing** (V2, V10, V14, V15).
3. **Internal testing** → create release → upload the `.aab` → add yourself/testers → install via the opt-in link on a real phone → run `TESTING.md` sections A–D on the **Play-delivered** build (this is the build users get; signing and per-ABI splits differ from your local APK).
4. Check **Pre-launch report** (Console → Testing) and **Android vitals** after some usage.
5. Closed test: add ≥ 12 testers (personal accounts), keep them opted in 14 days, publish a small update during the test (it helps your production-access answers), then **apply for production access**.
6. Production release: staged rollout (e.g. 10–20%) → watch crash/ANR rate → widen.

## 6. Go / no-go (all must be ticked)
- [ ] L1 signed with the upload key (jarsigner shows your cert, not Android Debug)
- [ ] L2 `targetSdkVersion` 36 in the built bundle
- [ ] L3 permissions as §1.3 and verified in the merged manifest
- [ ] L4 `check_16kb.sh` → ALL OK (or a written decision to accept the risk until 2027-02-01)
- [ ] L5/L6 release build exports on a real phone: X1, X2 pass (+ A1, L1, C2, C9)
- [ ] L7 privacy-policy URL live; L8/L9 notices done
- [ ] L10 split-clip fix merged with a test
- [ ] `scripts/dev.sh check` green
- [ ] Store listing, content rating, Data safety all submitted with no Console warnings
- [ ] Backup of the keystore + passwords stored outside the repo

## 7. After launch
Watch Console → **Android vitals** (crash and ANR rates; the Console shows its current "bad behaviour" thresholds), read reviews, keep `FACTS.md` updated, and plan the next release: P-1 (editor rebuilds), P1 (media copy to documents dir), F1 (delete/rename/duplicate projects — shipped 2026-10-11, not yet device-tested), F22 (foreground service for long exports).

## Sources checked 2026-10-11
- Play Help — Target API level requirements (Android 16 / API 36 for new apps and updates from 2026-08-31).
- developer.android.com — Support 16 KB page sizes (Play Console warning date 2027-02-01 for updates).
- Play Help — App testing requirements for new personal developer accounts (12 testers, 14 days, accounts after 2023-11-13).
- Play Help — Photo and Video Permissions policy (system picker for one-time/infrequent use; READ_MEDIA_IMAGES/VIDEO restricted).
- pub.dev — `ffmpeg_kit_flutter_new_full` (LGPL-3.0 "Full" variant, no GPL libs).
