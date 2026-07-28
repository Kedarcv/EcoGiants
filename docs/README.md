# Eco-Giants ZOU — Master Project Overview

## Project: Eco-Giants

A gamified, AI-powered waste-sorting mobile application for Zimbabwe Open University (ZOU), built for the RII Week Hackathon 2026 under the **Sustainable Universities and Green Innovation Challenge**.

---

## Quick Links

| Document | Path | Description |
|----------|------|-------------|
| **Architecture** | `docs/architecture/project-architecture.md` | System architecture, DDD bounded contexts, tech stack, data flow |
| **Flutter Structure** | `docs/architecture/flutter-app-structure.md` | Folder structure, BLoC pattern, dependency injection, routing |
| **Domain Models** | `docs/architecture/domain-models.md` | Entities, value objects, domain events, aggregates |
| **AI Integration** | `docs/architecture/ai-integration.md` | Waste classifier, bin recommender, LLM copilot architecture |
| **Gamification** | `docs/architecture/gamification-engine.md` | Points, levels, leaderboard, rewards system |
| **QR Verification** | `docs/architecture/qr-verification.md` | QR format, anti-gaming rules, security |
| **Live AI Tutor** | `docs/architecture/live-ai-tutor.md` | LiveKit video + NVIDIA LLM real-time tutor |
| **Feature Spec** | `docs/specifications/feature-specification.md` | User stories, acceptance criteria, priorities |
| **API Contract** | `docs/specifications/api-contract.md` | REST endpoints, request/response schemas, error codes |
| **Goal Tracker** | `docs/planning/goal-tracker.md` | Milestones, tasks, timeline, risk register |
| **Original Brief** | `Eco-Giants_ZOU_Project_Document.docx` | Source project document |

---

## Core Concept

```
Student takes photo of waste item
            │
            ▼
    AI Classifies Item
            │
            ▼
    Shows Category + Nearest Bin
            │
            ▼
    Student Walks to Bin
            │
            ▼
    Scans QR Code on Bin
            │
            ▼
    Verification + Points Awarded!
            │
            ▼
    Leaderboard Updated
    Level Progress Tracked
            │
            ▼
    Redeem Rewards at ZOU!
```

---

## Key Features

### MVP (Must Have for Hackathon)
- [x] Student registration & local auth (SharedPreferences + JSON)
- [x] AI waste classification (simulated YOLOv8, 5 categories)
- [x] Bin recommendation with campus directions
- [x] QR code verification at bins (anti-gaming)
- [x] Points system with weighted categories
- [x] Eco levels (5 tiers: Seedling → Eco Giant)
- [x] Campus leaderboard (seeded demo data + real user)
- [x] ZOU merchandise rewards catalog & redemption
- [x] LLM sustainability copilot (NVIDIA meta/llama-3.1-8b-instruct)
- [x] Disposal history view
- [x] Profile management
- [x] Onboarding flow (4 screens)
- [x] **Live AI Tutor** — LiveKit real-time video + NVIDIA LLM voice/text tutor (NEW)

### Tech Stack (All-Flutter)
| Component | Technology |
|-----------|-----------|
| Framework | Flutter 3.10+ |
| State Management | flutter_bloc (BLoC) |
| Navigation | go_router |
| Local Storage | SharedPreferences + JSON |
| Camera | image_picker |
| QR Scan | mobile_scanner |
| Charts | fl_chart |
| Animations | Built-in Flutter animations |
| HTTP | http (NVIDIA LLM API) |
| LLM | NVIDIA API — meta/llama-3.1-8b-instruct |
| Classification | YOLOv8 (simulated / ONNX ready) |

### Screens Built
| Screen | Status |
|--------|--------|
| Splash | ✅ |
| Onboarding (4 slides) | ✅ |
| Register | ✅ |
| Login | ✅ |
| Home Dashboard | ✅ |
| Camera / Image Picker | ✅ |
| Classification Result | ✅ |
| QR Scanner | ✅ |
| Verification Success | ✅ |
| Leaderboard | ✅ |
| Rewards Catalog | ✅ |
| Copilot Chat | ✅ |
| Disposal History | ✅ |
| Profile | ✅ |

## Quick Start

```bash
# 1. Navigate to project
cd /Users/mnkomo/Desktop/ZOU/src/mobile/eco_giants_app

# 2. Get dependencies
flutter pub get

# 3. Build Hive adapters (macOS)
dart run build_runner build --delete-conflicting-outputs

# 4. Run on device
flutter run
```

## Full User Flow

1. **Launch** → Splash (2s) → Onboarding (first time) → Register
2. **Home** → View points, level, streak, stats
3. **Scan Waste** → Camera/Gallery → AI Classification → Result Screen
4. **Go to Bin** → Follow directions → Tap "Scan QR"
5. **QR Verification** → Scan bin QR → Anti-gaming checks → Points awarded!
6. **Check Progress** → Leaderboard | Rewards | History | Profile
7. **Get Help** → AI Copilot with personalized insights

## Demo QR Codes
| Data | Bin | Category |
|------|-----|----------|
| EG_BIN001_REC_1722100000_A3F7 | Main Library | Recyclable |
| EG_BIN002_ORG_1722100000_B4E8 | Student Center | Organic |
| EG_BIN003_EWA_1722100000_C5D9 | IT Building | E-Waste |
| EG_BIN002_GEN_1722100000_D6EA | Student Center | General |
| EG_BIN001_HAZ_1722100000_E7FB | Main Library | Hazardous |

## Files Overview

```
lib/
├── main.dart                     # Entry point, Hive init
├── app.dart                      # MaterialApp + router + MultiBlocProvider
├── core/
│   ├── constants/app_constants.dart  # All app constants (categories, levels, points, QR config, NVIDIA)
│   └── theme/app_theme.dart      # Colors, text styles, Eco-Giants green theme
├── data/
│   ├── models/student_profile.dart   # Hive model (typeId: 0)
│   ├── models/disposal_record.dart   # Hive model (typeId: 1)
│   └── models/chat_message.dart      # Hive model (typeId: 2)
├── services/
│   ├── local_storage_service.dart    # Hive CRUD + leaderboard data seeding
│   ├── classification_service.dart   # YOLOv8 classification (simulated for now)
│   ├── verification_service.dart     # QR verification + anti-gaming + points calculation
│   └── nvidia_copilot_service.dart   # NVIDIA LLM API (meta/llama-3.1-8b-instruct)
├── presentation/
│   ├── blocs/
│   │   ├── home/home_bloc.dart       # Load profile, handle disposals
│   │   ├── classification/classification_bloc.dart  # Image classification
│   │   ├── qr_scan/qr_scan_bloc.dart # QR scanning + verification
│   │   └── copilot/copilot_bloc.dart # Chat with NVIDIA LLM
│   ├── screens/
│   │   ├── splash/splash_screen.dart
│   │   ├── onboarding/onboarding_screen.dart
│   │   ├── auth/register_screen.dart & login_screen.dart
│   │   ├── home/home_screen.dart
│   │   ├── camera/camera_screen.dart & result_screen.dart
│   │   ├── qr_scan/qr_scanner_screen.dart & verification_success_screen.dart
│   │   ├── leaderboard/leaderboard_screen.dart
│   │   ├── rewards/rewards_screen.dart
│   │   ├── copilot/chat_screen.dart
│   │   ├── history/disposal_history_screen.dart
│   │   └── profile/profile_screen.dart
│   └── widgets/
│       └── gamification/points_display.dart  # Points + progress bar widget
```

## Judging Alignment
| Criteria | How We Address It |
|----------|------------------|
| **Innovation (25%)** | AI + gamification + anti-gaming loop, all-Flutter architecture |
| **Technical Quality (25%)** | BLoC state management, clean architecture, external LLM integration |
| **Research Foundation (20%)** | Gamification for behavior change, public waste dataset |
| **Presentation** | Live demo with real photo → classification → QR → points flow |

*Document Version: 2.0 (All-Flutter Edition)*