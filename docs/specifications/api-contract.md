# Eco-Giants ZOU — Backend API Contract

## Base URL

```
Development: http://localhost:8000
Production: https://api.eco-giants.zou.ac.zw
```

## Authentication

All authenticated endpoints require:
```
Authorization: Bearer <jwt_token>
```

---

## Endpoints

### Authentication

#### POST /api/v1/auth/register
Register a new student account.

**Request:**
```json
{
  "email": "student@zou.ac.zw",
  "password": "SecurePass123",
  "display_name": "John Doe",
  "student_id": "ZOU2024001"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "student": {
      "id": "uuid",
      "email": "student@zou.ac.zw",
      "display_name": "John Doe",
      "student_id": "ZOU2024001",
      " eco_level": "Seedling",
      "total_points": 0,
      "created_at": "2026-07-27T10:00:00Z"
    },
    "tokens": {
      "access_token": "eyJhbGciOiJIUzI1NiIs...",
      "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
      "expires_in": 86400
    }
  }
}
```

**Errors:**
- `400` - Invalid email format or password requirements
- `409` - Email already registered
- `400` - Invalid ZOU email domain

---

#### POST /api/v1/auth/login
Authenticate and receive tokens.

**Request:**
```json
{
  "email": "student@zou.ac.zw",
  "password": "SecurePass123"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "tokens": {
      "access_token": "eyJhbGciOiJIUzI1NiIs...",
      "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
      "expires_in": 86400
    }
  }
}
```

---

#### POST /api/v1/auth/refresh
Refresh access token.

**Request:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "expires_in": 86400
  }
}
```

---

### Waste Classification

#### POST /api/v1/waste/classify
Upload and classify a waste item image.

**Request:**
```http
Content-Type: multipart/form-data

image: <binary_image_file>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "classification_id": "uuid",
    "category": "recyclable",
    "category_name": "Recyclable",
    "confidence": 0.94,
    "confidence_percentage": 94,
    "description": "Items that can be processed into new materials",
    "factoid": "Recycling one aluminum can saves enough energy to power a TV for 3 hours!",
    "recommended_bin": {
      "bin_id": "bin_001",
      "name": "Main Library - Floor 1",
      "location": "Near main entrance",
      "distance_meters": 150,
      "walking_time_seconds": 120,
      "qr_code": "EG_BIN_001_REC"
    },
    "image_url": "https://cdn.eco-giants.zou.ac.zw/items/uuid.jpg",
    "classified_at": "2026-07-27T10:00:00Z"
  }
}
```

**Errors:**
- `400` - Invalid image format (must be JPG/PNG)
- `400` - Image too large (max 5MB)
- `422` - Cannot classify image

---

#### POST /api/v1/waste/classify/manual
Submit manual category selection (when AI confidence is low).

**Request:**
```json
{
  "classification_id": "uuid",
  "selected_category": "recyclable",
  "reason": "low_confidence"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "classification_id": "uuid",
    "category": "recyclable",
    "recommended_bin": {
      "bin_id": "bin_001",
      "name": "Main Library - Floor 1",
      "qr_code": "EG_BIN_001_REC"
    }
  }
}
```

---

### QR Verification

#### POST /api/v1/verification/scan
Verify disposal by scanning bin QR code.

**Request:**
```json
{
  "classification_id": "uuid",
  "qr_code": "EG_BIN_001_REC",
  "location": {
    "latitude": -17.8249,
    "longitude": 31.0530
  }
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "verification_id": "uuid",
    "verified": true,
    "points_awarded": 30,
    "category": "recyclable",
    "total_points": 230,
    "eco_level": {
      "current": "Seedling",
      "next": "Sprout",
      "progress_percentage": 46,
      "points_to_next": 270
    },
    "streak": {
      "current_streak": 5,
      "streak_multiplier": 1.5,
      "bonus_points": 15
    },
    "verified_at": "2026-07-27T10:05:00Z"
  }
}
```

**Errors:**
- `400` - Invalid or expired QR code
- `429` - Too many verifications (rate limit)
- `409` - Already verified this item
- `400` - QR code doesn't match category
- `400` - Time window exceeded (must verify within 10 min)

---

### Gamification

#### GET /api/v1/gamification/score/me
Get current student's score and level.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "student_id": "uuid",
    "display_name": "John Doe",
    "total_points": 230,
    "eco_level": {
      "name": "Seedling",
      "number": 1,
      "min_points": 0,
      "max_points": 499,
      "icon": "🌱"
    },
    "next_level": {
      "name": "Sprout",
      "points_needed": 270
    },
    "progress_percentage": 46,
    "stats": {
      "total_disposals": 12,
      "by_category": {
        "recyclable": 5,
        "organic": 4,
        "e_waste": 1,
        "general": 2,
        "hazardous": 0
      },
      "current_streak": 5,
      "max_streak": 8
    }
  }
}
```

---

#### GET /api/v1/gamification/leaderboard
Get global leaderboard.

**Query Parameters:**
- `period` (optional): `all_time`, `weekly`, `monthly` (default: `all_time`)
- `limit` (optional): 1-100 (default: 50)
- `offset` (optional): 0+ (default: 0)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "leaderboard": [
      {
        "rank": 1,
        "student_id": "uuid1",
        "display_name": "Alice M.",
        "eco_level": "Eco Giant",
        "total_points": 12500,
        "disposal_count": 234
      },
      {
        "rank": 2,
        "student_id": "uuid2",
        "display_name": "Bob K.",
        "eco_level": "Protector",
        "total_points": 8200,
        "disposal_count": 189
      }
    ],
    "my_rank": {
      "rank": 47,
      "total_points": 230,
      "eco_level": "Seedling"
    },
    "total_participants": 523
  }
}
```

---

#### GET /api/v1/gamification/rewards
Get available rewards catalog.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "rewards": [
      {
        "reward_id": "reward_001",
        "name": "Eco-Friendly T-Shirt",
        "description": "100% organic cotton ZOU branded t-shirt",
        "image_url": "https://cdn.eco-giants.zou.ac.zw/rewards/tshirt.jpg",
        "required_level": "Sprout",
        "required_level_number": 2,
        "eligibility": {
          "eligible": false,
          "reason": "Current level: Seedling. Need: Sprout"
        }
      },
      {
        "reward_id": "reward_002",
        "name": "Stainless Steel Water Bottle",
        "description": "Reusable ZOU branded water bottle",
        "image_url": "https://cdn.eco-giants.zou.ac.zw/rewards/bottle.jpg",
        "required_level": "Guardian",
        "required_level_number": 3,
        "eligibility": {
          "eligible": false,
          "reason": "Current level: Seedling. Need: Guardian"
        }
      }
    ]
  }
}
```

---

#### POST /api/v1/gamification/rewards/{reward_id}/redeem
Redeem a reward.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "redemption_id": "uuid",
    "reward_name": "Eco-Friendly T-Shirt",
    "redemption_code": "EG-RWD-ABC123",
    "qr_code": "EG_RWD_ABC123",
    "redeemed_at": "2026-07-27T10:10:00Z",
    "expires_at": "2026-08-27T10:10:00Z",
    "status": "active"
  }
}
```

---

### LLM Copilot

#### POST /api/v1/copilot/chat
Send a message to the AI copilot.

**Request:**
```json
{
  "conversation_id": "uuid_or_null",
  "message": "How many items have I recycled this week?",
  "context": {
    "student_id": "uuid",
    "current_level": "Seedling",
    "total_points": 230
  }
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "conversation_id": "uuid",
    "message": {
      "id": "msg_002",
      "role": "assistant",
      "content": "Great question! You've recycled 5 items this week: 3 plastic bottles and 2 paper items. That earned you 90 points! At this rate, you'll reach 'Sprout' level in about 3 more days. Keep it up! 🌱",
      "timestamp": "2026-07-27T10:15:00Z",
      "sources": [
        {
          "type": "disposal_log",
          "period": "this_week",
          "count": 5
        }
      ]
    },
    "quick_replies": [
      "How do I reach the next level?",
      "What can I recycle?",
      "Show my weekly progress"
    ]
  }
}
```

---

### Profile & History

#### GET /api/v1/students/me
Get current student profile.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "student@zou.ac.zw",
    "display_name": "John Doe",
    "student_id": "ZOU2024001",
    "profile_image_url": "https://cdn.eco-giants.zou.ac.zw/profiles/uuid.jpg",
    "eco_level": "Seedling",
    "total_points": 230,
    "created_at": "2026-07-27T10:00:00Z",
    "stats": {
      "total_disposals": 12,
      "current_streak": 5
    }
  }
}
```

---

#### GET /api/v1/students/me/disposals
Get disposal history.

**Query Parameters:**
- `category` (optional): Filter by category
- `from_date` (optional): ISO date
- `to_date` (optional): ISO date
- `limit` (optional): Default 20
- `offset` (optional): Default 0

**Response (200):**
```json
{
  "success": true,
  "data": {
    "disposals": [
      {
        "id": "uuid",
        "category": "recyclable",
        "points": 30,
        "image_url": "https://cdn.eco-giants.zou.ac.zw/items/uuid.jpg",
        "bin_name": "Main Library - Floor 1",
        "verified": true,
        "created_at": "2026-07-27T10:05:00Z"
      }
    ],
    "total": 12,
    "limit": 20,
    "offset": 0
  }
}
```

---

## Error Response Format

All errors follow this structure:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The provided data is invalid",
    "details": {
      "email": ["Email must be a valid ZOU address"]
    }
  }
}
```

### Error Codes
| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_ERROR` | 400 | Invalid input data |
| `UNAUTHORIZED` | 401 | Missing or invalid token |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |
| `SERVICE_UNAVAILABLE` | 503 | External service down |

---

## Rate Limits

| Endpoint | Limit | Window |
|----------|-------|--------|
| /auth/* | 5 requests | 1 minute |
| /waste/classify | 10 requests | 1 minute |
| /verification/scan | 5 requests | 1 hour |
| /copilot/chat | 20 requests | 1 minute |
| Other endpoints | 60 requests | 1 minute |

---

*Document Version: 1.0*
*Last Updated: 27 July 2026*
