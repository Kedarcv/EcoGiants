# Eco-Giants ZOU — Feature Specification

## User Stories & Acceptance Criteria

### Feature Set 1: Identity & Authentication

#### US-001: Student Registration
**As a** ZOU student, **I want to** register with my student email, **so that** I can access the app.

**Acceptance Criteria:**
- [ ] Student can register with ZOU email format (@zou.ac.zw)
- [ ] Password must be minimum 8 characters with one uppercase, one number
- [ ] System validates email uniqueness
- [ ] Welcome email sent upon registration
- [ ] Student profile created with default eco level (Seedling)

**Priority:** P0 | **Estimate:** 2 days

#### US-002: Student Login
**As a** registered student, **I want to** log in securely, **so that** I can access my account.

**Acceptance Criteria:**
- [ ] Student can log in with email and password
- [ ] JWT token issued with 24-hour expiry
- [ ] Refresh token stored securely
- [ ] Biometric login option (Face ID / Fingerprint)
- [ ] Auto-login on app restart if token valid

**Priority:** P0 | **Estimate:** 1 day

#### US-003: Profile Management
**As a** student, **I want to** view and edit my profile, **so that** my information is current.

**Acceptance Criteria:**
- [ ] Display profile picture, name, email, eco level, total points
- [ ] Edit profile picture (camera or gallery)
- [ ] Edit display name
- [ ] View disposal statistics (total items, breakdown by category)
- [ ] View current eco level progress

**Priority:** P1 | **Estimate:** 2 days

---

### Feature Set 2: Waste Classification

#### US-004: Capture Waste Item
**As a** student, **I want to** photograph a waste item, **so that** the AI can classify it.

**Acceptance Criteria:**
- [ ] Open camera from home screen or floating action button
- [ ] Real-time camera preview with focus rectangle
- [ ] Capture photo with tap
- [ ] Option to retake or proceed
- [ ] Image compressed to max 2MB before upload
- [ ] Display captured image with loading state during classification

**Priority:** P0 | **Estimate:** 2 days

#### US-005: AI Classification Result
**As a** student, **I want to** see the classification result, **so that** I know which bin to use.

**Acceptance Criteria:**
- [ ] Display classified category (Recyclable, Organic, E-Waste, General, Hazardous)
- [ ] Show confidence score (percentage)
- [ ] Display category icon and color coding
- [ ] If confidence < 70%, prompt student to retake or select manually
- [ ] Show brief description of category
- [ ] Show environmental impact factoid (educational)

**Priority:** P0 | **Estimate:** 1 day

#### US-006: Manual Category Override
**As a** student, **I want to** manually select a category if AI is uncertain, **so that** I can still proceed.

**Acceptance Criteria:**
- [ ] Display 5 category options when confidence is low
- [ ] Student taps desired category
- [ ] System logs manual selection for ML improvement
- [ ] Proceed to bin recommendation

**Priority:** P1 | **Estimate:** 1 day

#### US-007: Bin Recommendation
**As a** student, **I want to** know which bin to use and where it is, **so that** I can dispose correctly.

**Acceptance Criteria:**
- [ ] Display nearest bin accepting the classified category
- [ ] Show bin location name (e.g., "Main Library - Floor 1")
- [ ] Show walking distance and estimated time
- [ ] Display bin on campus map (static image for MVP)
- [ ] Tap-to-navigate using external maps app
- [ ] Display bin type icon matching category color

**Priority:** P0 | **Estimate:** 2 days

---

### Feature Set 3: QR Verification

#### US-008: QR Code Scanning
**As a** student at the bin, **I want to** scan a QR code, **so that** my disposal is verified.

**Acceptance Criteria:**
- [ ] QR scanner opens from verification screen
-- [ ] Camera auto-focuses on QR code
- [ ] Scan completes within 2 seconds
- [ ] Haptic feedback on successful scan
- [ ] Display "Verifying..." loading state
- [ ] Handle scan errors gracefully with retry option

**Priority:** P0 | **Estimate:** 2 days

#### US-009: Verification Success & Points Award
**As a** student, **I want to** receive confirmation and points, **so that** I know my action was recorded.

**Acceptance Criteria:**
- [ ] Display success animation (confetti / checkmark)
- [ ] Show points awarded with breakdown
- [ ] Display updated total points
- [ ] Show eco level progress update
- [ ] Play success sound (optional, can be disabled)
- [ ] Add entry to disposal log

**Priority:** P0 | **Estimate:** 1 day

#### US-010: Anti-Gaming Protection
**As a** system, **I want to** prevent point farming, **so that** the leaderboard remains fair.

**Acceptance Criteria:**
- [ ] QR codes expire after 5 minutes
- [ ] Time window between classification and verification max 10 minutes
- [ ] Rate limiting: max 5 verifications per hour per student
- [ ] Location check: verify student is near bin (for full build)
- [ ] Duplicate prevention: same QR cannot be scanned twice by same student
- [ ] Suspicious activity flagged for review

**Priority:** P0 | **Estimate:** 2 days

---

### Feature Set 4: Gamification

#### US-011: Points System
**As a** student, **I want to** earn points for correct disposal, **so that** I am incentivized.

**Acceptance Criteria:**
- [ ] Points awarded per verified disposal
- [ ] Weighted points by category:
  - Hazardous: 50 points
  - E-Waste: 40 points
  - Recyclable: 30 points
  - Organic: 20 points
  - General: 10 points
- [ ] Streak bonus: consecutive days add multiplier (1.2x, 1.5x, 2x)
- [ ] Points history viewable in profile

**Priority:** P0 | **Estimate:** 1 day

#### US-012: Eco Levels
**As a** student, **I want to** progress through eco levels, **so that** I feel a sense of achievement.

**Acceptance Criteria:**
- [ ] 5 levels defined:
  - Seedling (0-499 points)
  - Sprout (500-1,499 points)
  - Guardian (1,500-4,999 points)
  - Protector (5,000-9,999 points)
  - Eco Giant (10,000+ points)
- [ ] Level-up animation on threshold cross
- [ ] Display level badge on profile
- [ ] Each level unlocks new rewards
- [ ] Progress bar visible on home screen

**Priority:** P0 | **Estimate:** 2 days

#### US-013: Leaderboard
**As a** student, **I want to** see how I rank against others, **so that** I feel competitive.

**Acceptance Criteria:**
- [ ] Global leaderboard showing top 50 students
- [ ] My rank displayed prominently
- [ ] Weekly and monthly views
- [ ] Display rank, name (masked), eco level, total points
- [ ] Top 3 get special trophy icons
- [ ] Pull-to-refresh
- [ ] Cached locally, updates every 5 minutes

**Priority:** P1 | **Estimate:** 2 days

#### US-014: Reward Redemption
**As a** student, **I want to** redeem my eco level for merchandise, **so that** I get tangible rewards.

**Acceptance Criteria:**
- [ ] Rewards catalog viewable by level
- [ ] Display reward image, description, required level
- [ ] "Redeem" button for eligible rewards
- [ ] Generate unique redemption code
- [ ] Display redemption code with QR (for ZOU staff scanning)
- [ ] Redemption history in profile
- [ ] Push notification when new level unlocks new rewards

**Priority:** P1 | **Estimate:** 2 days

---

### Feature Set 5: LLM Copilot

#### US-015: Copilot Chat Interface
**As a** student, **I want to** chat with an AI assistant, **so that** I get sustainability guidance.

**Acceptance Criteria:**
- [ ] Chat icon accessible from home screen
- [ ] Conversation history persists
- [ ] Typing indicator when AI is responding
- [ ] Send text messages
- [ ] Display AI responses in chat bubble format
- [ ] Clear conversation option
- [ ] Pre-set quick question buttons:
  - "How many items have I recycled?"
  - "What can I recycle?"
  - "How do I reach the next level?"

**Priority:** P1 | **Estimate:** 2 days

#### US-016: Personalized Insights
**As a** student, **I want to** receive personalized recycling insights, **so that** I can improve.

**Acceptance Criteria:**
- [ ] AI has access to student's disposal log as context
- [ ] Answers questions about personal recycling activity
- [ ] Suggests categories to focus on for next level
- [ ] Provides campus-specific sustainability tips
- [ ] Responds in conversational, encouraging tone

**Priority:** P2 | **Estimate:** 1 day

---

### Feature Set 6: Additional Features

#### US-017: Disposal History
**As a** student, **I want to** view my disposal history, **so that** I can track my progress.

**Acceptance Criteria:**
- [ ] Chronological list of all disposals
- [ ] Filter by category
- [ ] Filter by date range
- [ ] Display item thumbnail, category, points, date
- [ ] Infinite scroll pagination
- [ ] Export summary (shareable image)

**Priority:** P1 | **Estimate:** 1 day

#### US-018: Push Notifications
**As a** student, **I want to** receive notifications, **so that** I stay engaged.

**Acceptance Criteria:**
- [ ] Level-up notification
- [ ] Streak reminder ("You're on a 3-day streak! Don't break it!")
- [ ] Weekly summary notification
- [ ] New reward unlocked notification
- [ ] Customizable notification settings

**Priority:** P2 | **Estimate:** 1 day

#### US-019: Onboarding Flow
**As a** new student, **I want to** learn how to use the app, **so that** I can start quickly.

**Acceptance Criteria:**
- [ ] 4-screen onboarding carousel
  1. Welcome + app purpose
  2. How to classify waste (photo demo)
  3. QR verification at bin
  4. Points, levels, and rewards
- [ ] "Get Started" CTA to registration
- [ ] Skip option available
- [ ] Only shown on first launch

**Priority:** P1 | **Estimate:** 1 day

#### US-020: Offline Mode
**As a** student with poor connectivity, **I want to** use basic features offline, **so that** I'm not blocked.

**Acceptance Criteria:**
- [ ] Cache last known bin locations
- [ ] Queue disposals locally when offline
- [ ] Sync queued items when connectivity restored
- [ ] Display offline indicator
- [ ] Leaderboard shows last cached data with timestamp

**Priority:** P2 | **Estimate:** 2 days

---

## Feature Priority Matrix

| Priority | Features | Must Have for Hackathon |
|----------|----------|------------------------|
| P0 (Critical) | US-001, US-002, US-004, US-005, US-007, US-008, US-009, US-010, US-011, US-012 | YES |
| P1 (High) | US-003, US-006, US-013, US-014, US-015, US-017, US-019 | Nice to have |
| P2 (Medium) | US-016, US-018, US-020 | Post-hackathon |

---

*Document Version: 1.0*
*Last Updated: 27 July 2026*
