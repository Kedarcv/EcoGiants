# Eco-Giants — All-Flutter Architecture

## Overview

Eco-Giants ZOU is a purely Flutter-based mobile application with **no backend server**. All functionality runs on-device or calls external APIs directly from the app.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter App (iOS/Android)                │
│                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   UI Layer      │  │   BLoC Layer    │  │  Services   │ │
│  │   (Screens)     │  │   (State Mgmt)  │  │  (Business) │ │
│  │                 │  │                 │  │             │ │
│  │ • Home          │  │ • HomeBloc      │  │ • Local     │ │
│  │ • Camera        │  │ • Classification│  │   Storage   │ │
│  │ • Result        │  │   Bloc          │  │   (Hive)    │ │
│  │ • QR Scanner    │  │ • QrScanBloc    │  │ • YOLO      │ │
│  │ • Leaderboard   │  │ • CopilotBloc   │  │   Classifier│ │
│  │ • Rewards       │  │                 │  │ • QR Verify │ │
│  │ • Copilot Chat  │  │                 │  │ • Points    │ │
│  │ • History       │  │                 │  │ • NVIDIA    │ │
│  │ • Profile       │  │                 │  │   LLM API   │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Local Storage (Hive Boxes)                 │ │
│  │  • students (StudentProfile)                            │ │
│  │  • disposals (DisposalRecord)                           │ │
│  │  • chat (ChatMessage)                                   │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  External APIs:                                              │
│  • NVIDIA API (meta/llama-3.1-8b-instruct) — LLM Copilot    │
│  • Future: YOLOv8 ONNX/TFLite — On-device classification     │
└─────────────────────────────────────────────────────────────┘
```

---

## Full User Flow

### 1. Onboarding & Registration
```
Launch App → Splash Screen → Onboarding (4 slides) → Register
                                         ↓
                              Save StudentProfile to Hive
                              Auto-login next launch
```

### 2. Home Dashboard
```
Home Screen:
├── Header: Name, Eco Level Badge, Points, Progress Bar
├── Action Buttons: "Scan Waste" / "Find Bin"
├── Stats: Disposals | Today's Points | Best Streak
├── Quick Access: Leaderboard | Rewards | Copilot | History
└── Recent Activity: Category breakdown chips
```

### 3. Waste Classification Flow
```
Tap "Scan Waste"
    │
    ├── Take Photo (camera) or Pick from Gallery
    │
    ├── AI Classification (simulated for hackathon)
    │   └── Detects: Recyclable | Organic | E-Waste | General | Hazardous
    │
    └── Result Screen
        ├── Classified Category + Confidence Bar
        ├── Factoid (educational tip)
        ├── Points Preview
        ├── Nearest Bin Location
        └── "I'm at the Bin - Scan QR" CTA
```

### 4. QR Verification Flow
```
Tap "Scan QR" at Bin
    │
    ├── Open QR Scanner (mobile_scanner)
    ├── Scan QR Code → Parse "EG_BIN001_REC_..."
    │
    └── Anti-Gaming Checks (all on-device)
        ✓ QR format valid
        ✓ QR not expired (<5 min)
        ✓ Category matches classification
        ✓ Time window OK (<10 min since classification)
        ✓ Rate limit OK (<5/hour)
        ✓ Daily points cap OK (<200/day)
        ✓ Not duplicate QR (same user)
    │
    └── Success → Award Points → Save to Hive
        → Verification Success Screen (confetti + points)
```

### 5. Gamification Updates
```
Points Awarded → Check Streak Logic
    │
    ├── Update Total Points
    ├── Check eco-level threshold
    │   └── If crossed → Level Up! (animation)
    │
    └── Update Leaderboard
        └── Merge real user score with seeded demo students
```

### 6. Leaderboard
```
Leaderboard Screen:
├── Top 50 seeded demo students (Alice M., Bob K., etc.)
├── Real user merged at correct rank position
├── 🥇🥈🥉 trophy icons for top 3
└── "YOU" badge for current user
```

### 7. Rewards Catalog
```
Rewards Screen:
├── 5 reward tiers (T-Shirt → Ultimate Kit)
├── Locked items show grayed out with progress bar
├── Unlocked items show "Redeem" button
└── Redemption → Shows unique code + QR → Show to ZOU staff
```

### 8. AI Copilot (NVIDIA LLM)
```
Chat Screen:
├── Welcome message with quick reply suggestions
├── User types question → Send Message
├── Build context from disposal log (last 50 items)
    └── Total items, points, level, weekly stats, by category
├── Call NVIDIA API (meta/llama-3.1-8b-instruct)
├── Display AI response with quick reply chips
└── Persistent conversation history in Hive chat box
```

---

## Data Models

### StudentProfile (Hive typeId: 0)
| Field | Type |
|-------|------|
| id | String |
| email | String |
| displayName | String |
| totalPoints | int |
| currentStreak | int |
| maxStreak | int |
| lastDisposalDate | DateTime? |
| createdAt | DateTime |
| onboardingComplete | bool |

### DisposalRecord (Hive typeId: 1)
| Field | Type |
|-------|------|
| id | String |
| category | String |
| pointsAwarded | int |
| timestamp | DateTime |
| qrCode | String? |
| binName | String? |

### ChatMessage (Hive typeId: 2)
| Field | Type |
|-------|------|
| id | String |
| isUser | bool |
| text | String |
| timestamp | DateTime |
| quickReplies | List<String>? |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.24+ |
| State Management | flutter_bloc (BLoC pattern) |
| Navigation | go_router |
| Local DB | Hive (NoSQL key-value) |
| Camera | image_picker |
| QR Scan | mobile_scanner |
| Charts | fl_chart |
| Animations | flutter_animate, lottie |
| HTTP | http (for NVIDIA API) |
| LLM | NVIDIA API — meta/llama-3.1-8b-instruct |
| Classification | YOLOv8 (simulated for hackathon, ONNX ready) |

---

## Demo QR Codes (Print These!)

| QR Data | Bin | Category |
|---------|-----|----------|
| `EG_BIN001_REC_1722100000_A3F7` | Main Library | Recyclable |
| `EG_BIN002_ORG_1722100000_B4E8` | Student Center | Organic |
| `EG_BIN003_EWA_1722100000_C5D9` | IT Building | E-Waste |
| `EG_BIN002_GEN_1722100000_D6EA` | Student Center | General |
| `EG_BIN001_HAZ_1722100000_E7FB` | Main Library | Hazardous |

Print at 5cm x 5cm minimum. QR expires 5 minutes from generation.

---

## NVIDIA API Integration

**Endpoint:** `https://integrate.api.nvidia.com/v1/chat/completions`

**Model:** `meta/llama-3.1-8b-instruct`

**Context Building:**
- Student's total items disposed
- Total points + eco level
- Weekly stats
- Category breakdown
- All sent as system prompt context to LLM

---

## Future: YOLOv8 On-Device Classification

Current: Rule-based simulation (for hackathon speed)

Production:
1. Convert YOLOv8 `.pt` to ONNX/TFLite
2. Use `onnxruntime` or `tflite_flutter` package
3. Preprocess image → 640x640, normalize
4. Run inference on-device (50-100ms CPU)
5. Parse detections, map to 5 waste categories

Model source: https://github.com/teamsmcorg/Waste-Classification-using-YOLOv8

---

*Document Version: 1.0*
*Architecture: All-Flutter (No Backend)*
*Last Updated: 27 July 2026*
