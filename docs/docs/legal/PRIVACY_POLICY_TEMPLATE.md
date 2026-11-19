# Privacy Policy — Cliper  (TEMPLATE — fill the [BRACKETS], then publish at a public URL)

> **Not legal advice.** This template states what the app does *today* according to `docs/FACTS.md` (F-30…F-34). **Every sentence must stay true.** If you add analytics, ads, accounts, cloud features, voice recording, or any network feature, update this policy *and* the Play Data-safety form first.
> Updated 2026-11-17 for: Firebase Analytics + Crashlytics, optional Google sign-in (Firebase Auth), AdMob ads (Home banner, rewarded ad for 4K) with Google's consent message, and AI generation with the user's own key. Keep the Play **Data safety** form in step with sections 2–2c.

**App:** Cliper (`com.ayushstudio.clipforge`)
**Developer / controller:** [Your name or company], [country]
**Contact:** [support email]
**Effective date:** [YYYY-MM-DD]

## 1. Summary
Cliper is a video editor that works **on your device**. Your videos, photos, audio and projects are never uploaded to us. An account is optional. The free app shows ads. We collect usage statistics, crash reports and — if you sign in — your basic Google profile, as described below.

## 2. Information we collect
| Data | When | Why | Service |
|---|---|---|---|
| App usage events (e.g. which tools/templates are used, export quality, whether an export succeeded), device model, OS version, app version, approximate country, app-instance ID | While you use the app, unless you turn off **Settings → Privacy → Share usage & crash reports** | Improve the app, find broken features | Google Firebase Analytics |
| Crash reports (stack trace, device/OS, app state at the crash) | When the app crashes, unless turned off as above | Fix crashes | Google Firebase Crashlytics |
| Name, email address, profile photo, Google account ID | Only if you choose **Sign in with Google** | Identify your account | Google Firebase Authentication |
| Advertising ID, IP address, device information, ad interactions | When ads are shown (Home banner, optional rewarded ad for 4K export) | Show ads, measure them, prevent fraud; personalised ads only where you consented | Google AdMob |

We never collect your media, project contents, text you type into titles, AI prompts, or files. We do not sell personal information.

## 2a. Advertising and consent
Ads are served by Google AdMob. Where the law requires it (for example in the EEA, UK and Switzerland, and some US states), the app asks for your consent with Google's consent message before ads are personalised. You can change your choice any time in **Settings → Privacy → Ad privacy choices**, and you can reset or delete your advertising ID in Android settings. Google's policy: https://policies.google.com/technologies/partner-sites

## 2b. AI generation (optional)
If you add your own API key for an AI provider in Settings, the prompts you type and any reference image you choose are sent directly from your phone to that provider, under that provider's privacy policy. Cliper has no server in between and never receives them. Your key is stored encrypted on your phone.

## 2c. Retention
Analytics data: kept by Google for [14 / 26] months (your Firebase setting). Crash reports: up to 90 days. Account data: until you delete your account. Ad data: per Google's policies.

## 3. What stays on your device
- **Your media** (videos, photos, music) is accessed through the Android system picker when you choose it. Your original files are never modified.
- **Your projects** (edit instructions such as trim points, filters, text, and music settings) are stored in a database inside the app's private storage on your device.
- **Temporary files** (for example copies of imported media, thumbnails, and exported videos before you save them) are stored in the app's private storage and may be deleted by the system or when you uninstall the app.
- **Exported videos** are saved to your device's gallery (album "Cliper") when you export. They are yours; we do not receive a copy.

## 4. Permissions
| Permission | Why |
|---|---|
| Notifications (Android 13+) | To show export progress and completion. Optional. |
| Photos and videos / music and audio | So you can pick media to edit. |
| Microphone | Only when you record a voice-over. The recording stays on your phone. |
| Internet, network state | Ads, sign-in, analytics/crash reports, AI generation. |
| Advertising ID | Ads (see 2a). |
| [Storage (Android 9 and older only)] | To save the exported video to your gallery on old Android versions. [Delete this row if you remove the permission.] |
Media is selected with the system picker; the app does not request broad access to your photo library. [Keep only if true after the manifest cleanup.]

## 4a. Sharing
If you tap **Share**, the exported video is handed to the app *you* choose in the Android share sheet. That app's own privacy policy applies from that point.

## 5. Third-party software
Cliper includes open-source components (for example FFmpeg through FFmpegKit, and Flutter packages); they run on your device and do not transmit your data. It also uses the Google services listed in section 2 (Firebase Analytics, Crashlytics, Authentication; AdMob), which process data under Google's privacy policy: https://policies.google.com/privacy Licences: [URL to THIRD_PARTY_NOTICES or in-app screen].

## 6. Children
Cliper is not directed to children under [13 / 16], and its ads are not child-directed. We do not knowingly collect information from children. [Align with your Play "Target audience" answer.]

## 7. Data deletion
- **Account:** Settings → Account → **Delete account** deletes your Cliper account immediately. You can also email [support email] and we will delete it within 30 days.
- **Analytics / crash data:** turn off sharing in Settings; to have existing data deleted, email us with the app-instance ID shown [where] or your account email.
- **On your device:** clear the app's storage in Android settings or uninstall the app. Videos you already saved to your gallery remain until you delete them.

## 8. Changes
We will post any change to this policy at this URL and update the effective date.

## 9. Contact
[support email] — [postal address if required in your country]
