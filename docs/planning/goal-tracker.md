# Eco-Giants ZOU — Goal Tracker & Roadmap

## Timeline Overview

**Hackathon Date:** 28 July 2026 (Tomorrow!)
**Presentation Date:** 29-30 July 2026
**Total Build Window:** ~2-3 days

---

## Milestone 1: Foundation & Setup [Day 1 - Morning]
**Target:** 27 July 2026, 4:00 PM - 8:00 PM
**Goal:** Project scaffolding, environment setup, core configuration

| # | Task | Status | Owner | Est. Time | Dependencies |
|---|------|--------|-------|-----------|--------------|
| 1.1 | Create Flutter project structure | ⬜ | Dev 1 | 30 min | None |
| 1.2 | Set up FastAPI backend project | ⬜ | Dev 2 | 30 min | None |
| 1.3 | Configure Docker & Docker Compose | ⬜ | Dev 2 | 45 min | 1.2 |
| 1.4 | Set up PostgreSQL & Redis containers | ⬜ | Dev 2 | 30 min | 1.3 |
| 1.5 | Configure CI/CD pipeline (GitHub Actions) | ⬜ | Dev 2 | 45 min | None |
| 1.6 | Set up dependency injection (get_it) | ⬜ | Dev 1 | 30 min | 1.1 |
| 1.7 | Configure routing (go_router) | ⬜ | Dev 1 | 30 min | 1.1 |
| 1.8 | Set up BLoC state management | ⬜ | Dev 1 | 30 min | 1.1 |
| 1.9 | Configure HTTP client (dio) with interceptors | ⬜ | Dev 1 | 30 min | 1.1 |
| 1.10 | Set up local storage (Hive) | ⬜ | Dev 1 | 20 min | 1.1 |

**Deliverable:** Both projects compile and run. Can call a test endpoint.

---

## Milestone 2: Core Domain & Models [Day 1 - Afternoon]
**Target:** 27 July 2026, 8:00 PM - 11:00 PM
**Goal:** Domain entities, value objects, data models, database schema

| # | Task | Status | Owner | Est. Time | Dependencies |
|---|------|--------|-------|-----------|--------------|
| 2.1 | Define domain events (all contexts) | ⬜ | Dev 1 | 45 min | None |
| 2.2 | Create Student entity & aggregate | ⬜ | Dev 1 | 30 min | 2.1 |
| 2.3 | Create WasteItem entity & aggregate | ⬜ | Dev 1 | 30 min | 2.1 |
| 2.4 | Create Score/Reward entities (gamification) | ⬜ | Dev 1 | 30 min | 2.1 |
| 2.5 | Design database schema (SQLAlchemy models) | ⬜ | Dev 2 | 45 min | 2.1-2.4 |
| 2.6 | Create database migrations | ⬜ | Dev 2 | 30 min | 2.5 |
| 2.7 | Implement repository pattern (all contexts) | ⬜ | Dev 2 | 60 min | 2.5 |
| 2.8 | Create DTOs / serialization models | ⬜ | Dev 2 | 30 min | 2.5 |

**Deliverable:** Database migrations run successfully. All models defined.

---

## Milestone 3: Authentication & Identity [Day 1 - Late Night]
**Target:** 27-28 July 2026, 11:00 PM - 1:00 AM
**Goal:** Registration, login, JWT auth working end-to-end

| # | Task | Status | Owner | Est. Time | Dependencies |
|---|------|--------|-------|-----------|--------------|
| 3.1 | Implement JWT auth backend (register/login) | ⬜ | Dev 2 | 45 min | 2.5 |
| 3.2 | Create auth middleware | ⬜ | Dev 2 | 30 min | 3.1 |
| 3.3 | Build registration screen (Flutter) | ⬜ | Dev 1 | 30 min | 1.8, 3.1 |
| 3.4 | Build login screen (Flutter) | ⬜ | Dev 1 | 30 min | 1.8, 3.1 |
| 3.5 | Implement auth BLoC | ⬜ | Dev 1 | 30 min | 1.8 |
| 3.6 | Secure token storage (Flutter secure storage) | ⬜ | Dev 1 | 20 min | 3.5 |
| 3.7 | Auto-login on app start | ⬜ | Dev 1 | 20 min | 3.6 |
| 3.8 | Create profile screen (basic version) | ⬜ | Dev 1 | 30 min | 3.4-3.7 |

**Deliverable:** Can register, login, and view profile on the app.

---

## Milestone 4: AI Waste Classification [Day 2 - Morning]
**Target:** 28 July 2026, 6:00 AM - 10:00 AM
**Goal:** Working AI classifier with image capture and result display

| # | Task | Status | Owner | Est. Time | Dependencies |
|---|------|--------|-------|-----------|--------------|
| 4.1 | Integrate image_picker package | ⬜ | Dev 1 | 15 min | None |
| 4.2 | Build camera capture screen | ⬜ | Dev 1 | 45 min | 4.1 |
| 4.3 | Create image upload endpoint (FastAPI) | ⬜ | Dev 2 | 30 min | 3.1 |
| 4.4 | Integrate TFLite waste classifier model | ⬜ | Dev 2 | 60 min | 4.3 |
| 4.5 | Build classification result screen | ⬜ | Dev 1 | 45 min | 4.2 |
| 4.6 | Handle low-confidence scenarios | ⬜ | Dev 1 | 30 min | 4.5 |
| 4.7 | Save classification to database | ⬜ | Dev 2 | 20 min | 4.4 |
| 4.8 | Add educational factoids per category | ⬜ | Dev 1 | 20 min | 4.5 |

**Deliverable:** Can take photo of item, get classification result with confidence.

---

## Milestone 5: QR Verification & Points [Day 2 - Midday]
**Target:** 28 July 2026, 10:00 AM - 2:00 PM
**Goal:** QR scanning, verification, points awarded, anti-gaming

| # | Task | Status | Owner | Est. Time | Dependencies |
|---|------|--------|-------|-----------|--------------|
| 5.1 | Integrate mobile_scanner package | ⬜ | Dev 1 | 15 min | None |
| 5.2 | Build QR scanner screen | ⬜ | Dev 1 | 30 min | 5.1 |
| 5.3 | Generate QR codes for bins (Python script) | ⬜ | Dev 2 | 30 min | None |
| 5.4 | Create QR verification endpoint | ⬜ | Dev 2 | 45 min | 5.3 |
| 5.5 | Implement anti-gaming rules (time window, rate limit) | ⬜ | Dev 2 | 45 min | 5.4 |
| 5.6 | Points calculation logic | ⬜ | Dev 2 | 30 min | 5.5 |
| 5.7 | Build success screen with points animation | ⬜ | Dev 1 | 45 min | 5.2 |
| 5.8 | Build failure/retry screen | ⬜ | Dev 1 | 20 min | 5.7 |

**Deliverable:** Full classification → verification → points flow works end-to-end.

---

## Milestone 6: Gamification Engine [Day 2 - Afternoon]
**Target:** 28 July 2026, 2:00 PM - 6:00 PM
**Goal:** Levels, leaderboard, rewards system

| # | Task | Status | Owner | Est. Time | Dependencies |
|---|------|--------|-------|-----------|--------------|
| 6.1 | Implement eco level calculation logic | ⬜ | Dev 2 | 30 min | 5.6 |
| 6.2 | Create leaderboard endpoint (global + my rank) | ⬜ | Dev 2 | 30 min | 6.1 |
| 6.3 | Build leaderboard screen (Flutter) | ⬜ | Dev 1 | 45 min | 6.2 |
| 6.4 | Build rewards catalog screen | ⬜ | Dev 1 | 30 min | 6.1 |
| 6.5 | Implement reward redemption logic | ⬜ | Dev 2 | 30 min | 6.1 |
| 6.6 | Build redemption code display screen | ⬜ | Dev 1 | 30 min | 6.5 |
| 6.7 | Add level-up animation | ⬜ | Dev 1 | 30 min | 6.1 |
| 6.8 | Seed demo data for leaderboard | ⬜ | Dev 2 | 15 min | 6.2 |

**Deliverable:** Students can see leaderboard, track level progress, view rewards.

---

## Milestone 7: LLM Copilot [Day 2 - Evening]
**Target:** 28 July 2026, 6:00 PM - 9:00 PM
**Goal:** Basic chat interface with personalized Q&A

| # | Task | Status | Owner | Est. Time | Dependencies |
|---|------|--------|-------|-----------|--------------|
| 7.1 | Set up LLM API integration (OpenAI/Anthropic) | ⬜ | Dev 2 | 30 min | None |
| 7.2 | Create context builder (disposal log → prompt) | ⬜ | Dev 2 | 30 min | 7.1 |
| 7.3 | Build copilot chat screen (Flutter) | ⬜ | Dev 1 | 45 min | 1.8 |
| 7.4 | Implement chat BLoC | ⬜ | Dev 1 | 30 min | 7.3 |
| 7.5 | Add quick question buttons | ⬜ | Dev 1 | 15 min | 7.4 |
| 7.6 | Store conversation history locally | ⬜ | Dev 1 | 20 min | 1.10 |
| 7.7 | Add typing indicator | ⬜ | Dev 1 | 15 min | 7.3 |
| 7.8 | Create copilot API endpoint | ⬜ | Dev 2 | 30 min | 7.2 |

**Deliverable:** Can chat with AI copilot and get personalized answers.

---

## Milestone 8: Polish & Demo Preparation [Day 2 - Late Night]
**Target:** 28-29 July 2026, 9:00 PM - 12:00 AM
**Goal:** UI polish, demo script, bug fixes

| # | Task | Status | Owner | Est. Time | Dependencies |
|---|------|--------|-------|-----------|--------------|
| 8.1 | Add loading states and error handling | ⬜ | Dev 1 | 30 min | All |
| 8.2 | Implement splash screen with Eco-Giants branding | ⬜ | Dev 1 | 20 min | None |
| 8.3 | Add onboarding flow (4 screens) | ⬜ | Dev 1 | 30 min | 8.2 |
| 8.4 | Print demo QR codes for bins | ⬜ | Dev 2 | 15 min | 5.3 |
| 8.5 | Prepare demo dataset (10+ items, 5+ students) | ⬜ | Dev 2 | 20 min | All |
| 8.6 | Rehearse demo flow and timing | ⬜ | Both | 30 min | All |
| 8.7 | Fix critical bugs | ⬜ | Both | As needed | All |
| 8.8 | Build release APK/IPA | ⬜ | Dev 1 | 20 min | 8.7 |

**Deliverable:** Demo-ready app with polished UI and rehearsed pitch.

---

## Sprint Health Dashboard

| Milestone | Status | Progress | Risk Level |
|-----------|--------|----------|------------|
| M1: Foundation | 🔴 Not Started | 0% | Low |
| M2: Core Domain | 🔴 Not Started | 0% | Low |
| M3: Auth | 🔴 Not Started | 0% | Medium |
| M4: AI Classification | 🔴 Not Started | 0% | High |
| M5: QR Verification | 🔴 Not Started | 0% | High |
| M6: Gamification | 🔴 Not Started | 0% | Medium |
| M7: LLM Copilot | 🔴 Not Started | 0% | Low |
| M8: Polish & Demo | 🔴 Not Started | 0% | Medium |

---

## Risk Register

| # | Risk | Probability | Impact | Mitigation |
|---|------|-------------|--------|------------|
| R1 | TFLite model accuracy too low | Medium | High | Use pre-trained model, have manual fallback |
| R2 | QR scanning fails on stage | Medium | High | Print large QR codes, have backup demo video |
| R3 | Internet connectivity at venue | Medium | High | Offline mode, local demo data |
| R4 | Flutter build issues | Low | Medium | Test on target device early, have emulator backup |
| R5 | Time overrun on core features | High | High | Strict MVP scope, mock non-critical features |
| R6 | Team member availability | Medium | Medium | Document everything, parallelize work |

---

## Definition of Done

For each milestone to be considered complete:
- [ ] All tasks in milestone marked complete
- [ ] Code passes lint/static analysis
- [ ] Manual smoke tests pass
- [ ] Feature demo recorded (for playback if live fails)
- [ ] Documentation updated

---

## Post-Hackathon Roadmap

### Phase 2: Production Readiness (Week 1-2 Post-Hackathon)
- [ ] Comprehensive testing (unit, integration, e2e)
- [ ] Security audit and hardening
- [ ] Performance optimization
- [ ] Database indexing and query optimization
- [ ] Proper error logging and monitoring

### Phase 3: Feature Completion (Week 3-4 Post-Hackathon)
- [ ] Full GPS navigation to bins
- [ ] Push notifications
- [ ] Offline mode with sync
- [ ] Enhanced LLM copilot with RAG
- [ ] Admin dashboard for ZOU staff

### Phase 4: Scale & Deploy (Week 5-6 Post-Hackathon)
- [ ] Cloud deployment (AWS/GCP)
- [ ] CI/CD fully automated
- [ ] Analytics and reporting
- [ ] App Store / Play Store submission

---

*Document Version: 1.0*
*Last Updated: 27 July 2026*
*Next Review: Daily during hackathon build*
