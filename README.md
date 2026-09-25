# BudgetMate — Flutter Native App

A native mobile budget manager built with Flutter/Dart. No Generative AI, LLM APIs,
or cloud AI services are used anywhere — all "intelligent" behavior (voice transaction
parsing, category classification, voice queries) is rule-based/deterministic NLP,
matching the original project spec.

## What's included (Phase 1)

- Auth (sign up / log in / log out / forgot password / change password), data isolated
  per user in local device storage
- Dashboard with summary cards and charts (income vs expense, category breakdown)
- Income & expense CRUD with all specified categories and payment methods
- Voice transaction entry (English / Tamil / Hindi + mixed speech) using the device's
  built-in speech recognizer, parsed with a rule-based keyword/regex engine, always
  shown as an editable confirmation screen with per-field confidence before saving
- Voice budget queries ("How much did I spend this month?") via intent classification
  against your real local data
- Budgets with configurable moderate/warning thresholds and progress bars
- Savings goals with required-monthly-savings calculation
- Transaction history with search/filter/sort
- Reports with date range, category breakdown, and CSV export/share
- Light/dark theme

## Not yet built (Phase 2 — say the word and I'll add these)

Receipt OCR scanning, recurring transactions, anomaly detection (Z-score/IQR),
spending prediction (moving average/regression), and the "learn from corrections"
feedback loop for the classifier.

## Setup

This folder contains the Dart source (`lib/`) and `pubspec.yaml`, but not the
generated native Android/iOS project shells (those are large, platform-specific,
and best generated fresh by the Flutter SDK rather than hand-written). To run it:

```bash
# 1. Make sure Flutter is installed: https://docs.flutter.dev/get-started/install
flutter --version

# 2. From inside this folder, generate the native android/ and ios/ project shells
#    (this will not overwrite lib/ or pubspec.yaml)
flutter create .

# 3. Get dependencies
flutter pub get

# 4. Run on a connected device or emulator
flutter run
```

## Required permissions

After `flutter create .`, add these before your first run:

**android/app/src/main/AndroidManifest.xml** — inside `<manifest>`, above `<application>`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```
(`INTERNET` is only needed if your device's speech engine uses network recognition;
on-device recognition works fully offline where the OS supports it.)

**ios/Runner/Info.plist** — add:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>BudgetMate needs the microphone to record your voice transactions.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>BudgetMate uses speech recognition to turn your voice into a transaction entry.</string>
```

## Notes on the ML/NLP approach

- **Voice-to-transaction parsing** (`lib/nlp_service.dart`) uses keyword dictionaries
  (English/Tamil/Hindi/mixed) + regex for amounts and relative dates — swap in a
  trained classifier later without touching the UI, since it returns the same
  `ParsedTransaction` shape.
- **Voice queries** use a small fixed intent list resolved by keyword match, then
  answered from real local data — never invented.
- **Password hashing** here is unsalted SHA-256 for local demo purposes. A
  production release should use a real backend with salted hashing rather than
  on-device-only credential storage.
- Tamil/Hindi speech recognition quality depends entirely on the phone's installed
  OS language/voice packs — this is a device capability, not something the app
  code controls.

## Project structure

```
lib/
  main.dart               entry point, routes to AuthScreen or HomeShell
  app_state.dart           ChangeNotifier holding session + all financial data
  models.dart               Transaction, SavingsGoal, Thresholds, UserData
  storage_service.dart      local persistence + auth (SharedPreferences)
  nlp_service.dart          rule-based voice parsing + query intent classifier
  theme.dart / utils.dart   theming and ₹ formatting helpers
  screens/                  one file per app screen
  widgets/tx_modal.dart     add/edit transaction bottom sheet
```
