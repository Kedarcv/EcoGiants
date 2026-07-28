# Eco-Giants — Agent Guidance

## Project Overview
Eco-Giants is a gamified, AI-powered waste-sorting mobile application for Zimbabwe Open University (ZOU), built for the RII Week Hackathon 2026 under the Sustainable Universities and Green Innovation Challenge.

## Technology Stack
- **Framework**: Flutter 3.38.3, Dart 3.10.1
- **State Management**: ChangeNotifier (Provider pattern)
- **Local Storage**: SQLite (sqflite) + SharedPreferences
- **AI**: TFLite (on-device classifier) + NVIDIA API (Llama-3.1-8B LLM)
- **Real-time**: LiveKit Cloud (WebSocket signalling for Live AI Tutor)
- **Camera**: image_picker + camera (Live AI mode)
- **QR Scan**: mobile_scanner
- **TTS**: flutter_tts

## Key Architecture Patterns
- **Routes**: All screens registered in `lib/routes.dart` via named routes
- **Database**: `DatabaseManager` singleton handles all CRUD via sqflite
- **Models**: `User`, `Item`, `Category`, `Reward`, `Tips`, `DisposalRecord`
- **Notifiers**: `UserNotifier`, `ItemNotifier`, `CategoryNotifier`, `RewardNotifier`, `TipsNotifier`

## Build & Run
```bash
# Get dependencies
flutter pub get

# Analyze
flutter analyze

# Build Android debug APK
flutter build apk --debug

# Build & run on connected iOS device (requires Xcode + Apple ID)
flutter run
```

## Platform-Specific Setup

### Android
- **compileSdk**: Uses `flutter.compileSdkVersion`
- **Permissions**: Camera, Microphone, Internet, Network (see `AndroidManifest.xml`)
- **Min SDK**: `flutter.minSdkVersion`
- **Kotlin**: 1.9.0, **AGP**: 8.9.1, **Gradle**: 8.11.1

### iOS
- **Bundle ID**: `com.ecogiants.zou.app`
- **Display Name**: Eco-Giants
- **Team**: `SFTLP3DWGA` (Apple Development: michael.nkomo@cassavaai.co.zw)
- **Signing**: Automatic provisioning
- **Permissions**: Camera, Photo Library, Microphone (see `Info.plist`)

## External Services & Secrets
| Service | Key/Token | File |
|---------|-----------|------|
| LiveKit Cloud | API Key + Secret | `lib/services/livekit_config.dart` |
| NVIDIA LLM | API Key | `lib/services/livekit_config.dart` |

> ⚠️ These secrets are hardcoded for the hackathon demo. In production, move to a backend proxy.

## File Structure
```
lib/
├── main.dart                           # Entry point, MultiProvider
├── routes.dart                         # Named route definitions
├── database_manager.dart               # SQLite singleton
├── services/
│   ├── livekit_config.dart             # LiveKit + NVIDIA constants
│   ├── nvidia_chat_service.dart        # Streaming LLM client
│   └── livekit_room_manager.dart       # Room lifecycle + TTS
├── screens/
│   ├── SplashScreen.dart
│   ├── OnboardingScreen.dart
│   ├── HomeScreen.dart                 # Dashboard + Quick Actions
│   ├── UserScreen.dart
│   ├── LiveAiScreen.dart               # Live AI Tutor (NEW)
│   ├── QRScannerScreen.dart
│   ├── VerificationSuccessScreen.dart
│   ├── LeaderboardScreen.dart
│   ├── RewardsScreen.dart
│   ├── DisposalHistoryScreen.dart
│   └── SettingsScreen.dart
├── models/
│   ├── User.dart
│   ├── Item.dart
│   ├── Category.dart
│   ├── reward.dart
│   ├── Tips.dart
│   └── disposal_record.dart
├── controller/
│   ├── user_notifier.dart
│   ├── item_notifier.dart
│   ├── category_notifier.dart
│   ├── reward_notifier.dart
│   └── tips_notifier.dart
├── components/
│   └── (reusable UI widgets)
└── constants/
    ├── app_properties.dart
    ├── size_config.dart
    └── onboarding_contents.dart
```

## Gamification System
| Level | Points Required | Icon |
|-------|----------------|------|
| Seedling | 0 | 🌱 |
| Sprout | 50 | 🌿 |
| Sapling | 150 | 🌲 |
| Guardian | 300 | 🛡️ |
| Eco Giant | 500 | 🌍 |

- **Daily Cap**: 100 points max per day
- **Streak Bonus**: Consecutive days earn extra points
- **Categories & Points**: Recyclable (20), Organic (15), E-Waste (25), Hazardous (30), General (10)

## New Feature: Live AI Tutor
Added Jul 28, 2026. See `docs/architecture/live-ai-tutor.md` for full spec.
- Real-time camera feed visible to the AI
- Text or quick-prompt questions
- NVIDIA Llama-3.1-8B streaming responses
- Text-to-speech synthesis (friendly student tone)
- LiveKit Cloud WebSocket signalling

## CI / Deployment
- No CI configured (local build only)
- iOS requires manual Xcode signing setup (Apple ID: cvlised360@gmail.com)
- Android builds debug APK successfully on current toolchain

*Document Version: 1.1 (Live AI Tutor Edition)*
