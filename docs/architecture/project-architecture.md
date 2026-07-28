# Eco-Giants ZOU — Project Architecture

## Overview

Eco-Giants is a gamified, AI-powered waste-sorting mobile application for Zimbabwe Open University (ZOU). The system follows Domain-Driven Design (DDD) with clearly bounded contexts, clean architecture, and event sourcing for state changes.

---

## Domain Model Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Eco-Giants App                               │
│                                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌──────────┐  │
│  │  Identity   │  │   Waste     │  │Gamification │  │    LLM    │  │
│  │   Context   │  │  Context    │  │   Context   │  │  Context  │  │
│  │             │  │             │  │             │  │           │  │
│  │ • Students  │  │ • Items     │  │ • Points    │  │ • Copilot │  │
│  │ • Auth      │  │ • Bins      │  │ • Levels    │  │ • Chat    │  │
│  │ • Profiles  │  │ • Disposals │  │ • Rewards   │  │ • Log Q&A │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  └──────────┘  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              Shared Kernel (Events, Types, Utils)            │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Bounded Contexts

### 1. Identity Context

Responsible for student authentication, profiles, and account management.

| Aggregate | Entities | Value Objects |
|-----------|----------|---------------|
| Student | Student, Session | StudentId, Email, PasswordHash |

**Events:**
- `StudentRegistered`
- `StudentLoggedIn`
- `StudentProfileUpdated`

### 2. Waste Classification Context

Handles AI-powered waste classification, bin recommendations, and QR verification.

| Aggregate | Entities | Value Objects |
|-----------|----------|---------------|
| WasteItem | WasteItem, DisposalLog | WasteCategory, BinId, QrCode |
| BinLocation | BinLocation | GeoLocation, BinType |

**Events:**
- `ItemClassified`
- `DisposalVerified`
- `BinLocationUpdated`

### 3. Gamification Context

Manages points, eco levels, leaderboards, and reward redemption.

| Aggregate | Entities | Value Objects |
|-----------|----------|---------------|
| Score | Score, LeaderboardEntry | Points, EcoLevel, Rank |
| Reward | Reward, Redemption | RewardId, RedemptionCode |

**Events:**
- `PointsAwarded`
- `EcoLevelUnlocked`
- `RewardRedeemed`
- `LeaderboardUpdated`

### 4. LLM Copilot Context

Provides conversational interface for sustainability Q&A and disposal log insights.

| Aggregate | Entities | Value Objects |
|-----------|----------|---------------|
| Conversation | Conversation, Message | MessageId, CopilotQuery |

**Events:**
- `ConversationStarted`
- `MessageExchanged`

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Presentation Layer                            │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                Flutter Mobile App (iOS/Android)               │    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────────────┐  │    │
│  │  │ Camera   │ │ QR Scan  │ │ Leader-  │ │ Copilot Chat   │  │    │
│  │  │ Capture  │ │ & Verify │ │ board    │ │ Interface      │  │    │
│  │  └──────────┘ └──────────┘ └──────────┘ └────────────────┘  │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ HTTPS / REST / WebSocket
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         API Gateway                                  │
│         (Rate limiting, Auth middleware, Request routing)            │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
┌───────────────────────┐ ┌──────────────┐ ┌──────────────────────┐
│    Application Layer   │ │   AI Layer   │ │   Infrastructure     │
│       (FastAPI)        │ │              │ │       Layer          │
│  ┌─────────────────┐  │ │ ┌──────────┐ │ │  ┌────────────────┐  │
│  │ Auth Service    │  │ │ │ Classifier│ │ │  │ PostgreSQL     │  │
│  │ Waste Service   │  │ │ │ (MobileNet│ │ │  │   (primary DB) │  │
│  │ Game Service    │  │ │ │ /Efficient│ │ │  └────────────────┘  │
│  │ Copilot Service │  │ │ │ Net)      │ │ │  ┌────────────────┐  │
│  └─────────────────┘  │ │ └──────────┘ │ │  │ Redis          │  │
│                       │ │              │ │  │   (cache/sessions)│  │
│  ┌─────────────────┐  │ │ ┌──────────┐ │ │  └────────────────┘  │
│  │ Event Bus       │  │ │ │ LLM API  │ │ │  ┌────────────────┐  │
│  │ (pub/sub)       │  │ │ │ Wrapper  │ │ │  │ Cloud Storage  │  │
│  └─────────────────┘  │ │ │ (OpenAI  │ │ │  │   (images)     │  │
│                       │ │ │ /Claude)  │ │ │  └────────────────┘  │
└───────────────────────┘ │ └──────────┘ │ └──────────────────────┘
                          └──────────────┘
```

---

## Technology Stack

### Frontend (Mobile)
| Component | Technology | Version |
|-----------|-----------|---------|
| Framework | Flutter | ^3.24.0 |
| Language | Dart | ^3.5.0 |
| State Management | flutter_bloc (BLoC) | ^8.1.4 |
| Dependency Injection | get_it + injectable | ^7.7.0 |
| HTTP Client | dio | ^5.7.0 |
| Image Capture | image_picker | ^1.1.2 |
| QR Scanning | mobile_scanner | ^5.1.1 |
| Camera | camera | ^0.11.0 |
| Local Storage | hive | ^2.2.3 |
| Charts | fl_chart | ^0.68.0 |
| Routing | go_router | ^14.2.0 |

### Backend (API)
| Component | Technology | Version |
|-----------|-----------|---------|
| Framework | FastAPI | ^0.112.0 |
| Language | Python | ^3.11 |
| ORM | SQLAlchemy 2.0 | ^2.0.32 |
| Database | PostgreSQL | ^15 |
| Cache | Redis | ^7 |
| Auth | JWT (PyJWT) | ^2.9.0 |
| ML Framework | TensorFlow Lite | ^2.17.0 |
| LLM Integration | OpenAI API / Anthropic | Latest |
| ASGI Server | Uvicorn | ^0.30.0 |

### DevOps & Infrastructure
| Component | Technology |
|-----------|-----------|
| Containerization | Docker |
| Orchestration | Docker Compose (local) |
| CI/CD | GitHub Actions |
| Cloud (optional) | AWS / Google Cloud / Heroku |

---

## Event Sourcing Architecture

All domain state changes are captured as immutable events. This enables:
- Complete audit trail of student actions
- Rebuilding state from event log (time-travel debugging)
- Analytics on student behavior patterns

```dart
abstract class DomainEvent {
  final String eventId;
  final DateTime timestamp;
  final String aggregateId;

  DomainEvent({
    required this.eventId,
    required this.timestamp,
    required this.aggregateId,
  });
}

// Example events
class ItemClassified extends DomainEvent {
  final String studentId;
  final WasteCategory category;
  final String imageUrl;
  final double confidence;

  ItemClassified({
    required super.eventId,
    required super.timestamp,
    required super.aggregateId,
    required this.studentId,
    required this.category,
    required this.imageUrl,
    required this.confidence,
  });
}

class PointsAwarded extends DomainEvent {
  final String studentId;
  final int points;
  final String reason;
  final WasteCategory category;

  PointsAwarded({
    required super.eventId,
    required super.timestamp,
    required super.aggregateId,
    required this.studentId,
    required this.points,
    required this.reason,
    required this.category,
  });
}
```

---

## Data Flow

### 1. Waste Classification Flow
```
Student opens app → Camera capture → Upload image → 
AI Classifier → Return category + confidence → 
Display category + bin recommendation → 
Student navigates to bin
```

### 2. Verification Flow
```
Student arrives at bin → Scan QR code → 
Backend verifies QR + location + recent classification → 
Award points → Update leaderboard → Notify student
```

### 3. Gamification Flow
```
Points awarded → Check eco-level thresholds → 
If threshold crossed → Unlock level → 
Check reward eligibility → Allow redemption
```

### 4. LLM Copilot Flow
```
Student asks question → Backend fetches disposal log → 
Format as context → Call LLM API → 
Return personalized response → Display in chat UI
```

---

## Security Architecture

1. **Authentication**: JWT tokens with refresh token rotation
2. **API Rate Limiting**: Prevent abuse of classification endpoint
3. **Image Validation**: File type/size checks, malware scanning
4. **QR Anti-Gaming**: Time-bound tokens, location verification
5. **Data Protection**: Student data encrypted at rest and in transit
6. **Input Sanitization**: All user inputs validated at system boundaries

---

## Scalability Considerations

1. **AI Model**: Deploy classifier on edge (TensorFlow Lite) to reduce latency
2. **Caching**: Redis cache for leaderboard and frequent queries
3. **Database Indexing**: Indexes on student_id, timestamp, and category
4. **CDN**: Cloud storage CDN for waste item images
5. **Background Jobs**: Async processing for LLM copilot responses

---

## File Organization

```
/Users/mnkomo/Desktop/ZOU/
├── docs/
│   ├── architecture/
│   │   ├── project-architecture.md          (This file)
│   │   ├── flutter-app-structure.md
│   │   ├── domain-models.md
│   │   ├── ai-integration.md
│   │   ├── gamification-engine.md
│   │   └── qr-verification.md
│   ├── specifications/
│   │   ├── feature-specification.md
│   │   └── api-contract.md
│   ├── planning/
│   │   └── goal-tracker.md
│   └── design/
│       └── (UI mockups, wireframes)
├── src/
│   ├── mobile/
│   │   └── eco_giants_app/                  (Flutter project)
│   └── backend/
│       └── api/                             (FastAPI project)
├── tests/
│   ├── mobile/
│   └── backend/
├── config/
│   ├── docker/
│   ├── nginx/
│   └── environment/
├── scripts/
│   ├── setup/
│   └── deploy/
└── Eco-Giants_ZOU_Project_Document.docx
```

---

*Document Version: 1.0*
*Last Updated: 27 July 2026*
