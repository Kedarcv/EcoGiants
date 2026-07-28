# Eco-Giants ZOU — Gamification Engine

## Overview

The gamification engine transforms correct waste disposal into an engaging game through points, eco levels, leaderboards, and tangible rewards.

---

## 1. Points System

### Point Allocation by Category

| Category | Base Points | Rationale |
|----------|------------|-----------|
| **Hazardous** | 50 | Highest impact, requires special handling |
| **E-Waste** | 40 | Toxic materials, difficult to recycle |
| **Recyclable** | 30 | High value, reduces landfill |
| **Organic** | 20 | Easy to dispose, but still important |
| **General** | 10 | Baseline, still encourages proper bin use |

### Streak Multipliers

| Streak Days | Multiplier | Example |
|-------------|-----------|---------|
| 1-2 days | 1.0x | 30 pts |
| 3-6 days | 1.2x | 36 pts |
| 7-13 days | 1.5x | 45 pts |
| 14-29 days | 2.0x | 60 pts |
| 30+ days | 2.5x | 75 pts |

### Streak Milestone Bonuses

| Milestone | Bonus Points |
|-----------|-------------|
| 7 days | +50 |
| 14 days | +100 |
| 30 days | +250 |
| 60 days | +500 |
| 100 days | +1000 |

### Daily Caps
- **Max points per day**: 200 points
- **Min time between disposals**: 5 minutes
- **Max verifications per hour**: 5

---

## 2. Eco Levels

| Level | Name | Min Points | Max Points | Icon | Perks |
|-------|------|------------|------------|------|-------|
| 1 | **Seedling** | 0 | 499 | 🌱 | Basic leaderboard access |
| 2 | **Sprout** | 500 | 1,499 | 🌿 | T-shirt eligibility, weekly reports |
| 3 | **Guardian** | 1,500 | 4,999 | 🌳 | Water bottle eligibility |
| 4 | **Protector** | 5,000 | 9,999 | 🛡️ | Pen set eligibility, VIP badge |
| 5 | **Eco Giant** | 10,000+ | ∞ | 🌍 | All merch + Hall of Fame |

---

## 3. Rewards Catalog

| Reward | Required Level | Stock | Description |
|--------|---------------|-------|-------------|
| Organic Cotton T-Shirt | Sprout | Unlimited | ZOU branded eco t-shirt |
| Steel Water Bottle | Guardian | Unlimited | Reusable 500ml bottle |
| Eco Pen Set | Guardian | 100 | Recycled material pens |
| Eco Giant Hoodie | Protector | 50 | Premium organic hoodie |
| Ultimate Kit | Eco Giant | 20 | T-shirt + Bottle + Hoodie + Certificate |

---

## 4. Leaderboard Design

- **Global**: All-time top 50 students
- **Weekly**: Sunday to Sunday
- **Monthly**: Calendar month
- **My Rank**: Always displayed with top 3 highlighted (🥇🥈🥉)
- **Privacy**: Names masked (e.g., "Alice M.", "Bob K.")

---

## 5. Notification Events

| Event | Message | Priority |
|-------|---------|----------|
| **Level Up** | 🎉 Congratulations! You've reached Sprout! | HIGH |
| **Streak Milestone** | 🔥 7-day streak! +50 bonus points! | HIGH |
| **Streak at Risk** | ⚠️ Your streak expires soon! | MEDIUM |
| **New Reward** | 🎁 New reward unlocked! | MEDIUM |
| **Leaderboard Jump** | 📈 You moved up 5 spots! | LOW |
| **Weekly Summary** | 📊 This week: 15 items, 320 pts | LOW |

---

## 6. Anti-Gaming Rules

1. **Daily Cap**: 200 points maximum per day
2. **Time Window**: 5 minutes minimum between disposals
3. **QR Cooldown**: Cannot reuse same QR within 24 hours by same student
4. **Streak Window**: Must dispose within 48 hours to maintain streak
5. **Suspicious Rate**: 10+ disposals/hour = manual review
6. **Category Match**: QR category must match classified item

---

*Document Version: 1.0*
*Last Updated: 27 July 2026*
