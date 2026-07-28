# Eco-Giants ZOU — QR Verification & Anti-Gaming

## Overview

The QR verification system ensures points are only awarded for verified physical disposals, preventing fake submissions and point farming.

---

## 1. QR Code Format

```
Format: EG_{BIN_ID}_{CATEGORY}_{TIMESTAMP}_{CHECKSUM}

Example: EG_BIN001_REC_1722072600_A3F7

Components:
├── Prefix: "EG" (Eco-Giants)
├── Bin ID: "BIN001"
├── Category: "REC" (Recyclable)
│   ├── REC = Recyclable
│   ├── ORG = Organic
│   ├── EWA = E-Waste
│   ├── GEN = General
│   └── HAZ = Hazardous
├── Timestamp: Unix timestamp (10 min window)
└── Checksum: CRC16 (4 hex chars)
```

---

## 2. Verification Rules

| Rule | Value | Purpose |
|------|-------|---------|
| **QR Expiry** | 5 minutes | Prevent replay of old QR photos |
| **Classification Window** | 10 minutes | Must verify soon after classification |
| **Category Match** | Required | QR category must match classified item |
| **No Duplicates** | Yes | Same item cannot be verified twice |
| **Rate Limit** | 5/hour | Prevent rapid point farming |
| **Daily Cap** | 200 points | Max daily points per student |
| **QR Cooldown** | 24 hours | Same student cannot reuse same QR |
| **Suspicious Rate** | 10/hour | Flag for manual review |

---

## 3. Verification Flow

```
Student scans QR
        │
        ▼
┌─────────────────────┐
│ 1. Parse QR format  │
│ 2. Verify checksum  │
│ 3. Check expiry     │
│ 4. Match category   │
│ 5. Check timeline   │
│ 6. Check rate limit │
│ 7. Award points     │
└─────────────────────┘
        │
        ▼
   Success / Error
```

---

## 4. Demo QR Codes for Hackathon

Print these at minimum 5cm x 5cm:

| QR Code | Bin | Category | For Testing |
|---------|-----|----------|-------------|
| `EG_BIN001_REC_1722072600_A3F7` | Main Library | Recyclable | Plastic bottle |
| `EG_BIN002_ORG_1722072600_B4E8` | Student Center | Organic | Food waste |
| `EG_BIN003_EWA_1722072600_C5D9` | IT Building | E-Waste | Old phone |
| `EG_BIN002_GEN_1722072600_D6EA` | Student Center | General | Paper waste |
| `EG_BIN001_HAZ_1722072600_E7FB` | Main Library | Hazardous | Dead battery |

---

## 5. Security Measures

1. **Server-side validation**: All rules enforced on backend
2. **Checksum**: CRC16 prevents fake QR generation
3. **Secret key**: Required for valid checksums
4. **Time-bound**: QR codes expire after 5 minutes
5. **Rate limiting**: Redis-backed sliding window
6. **Audit log**: Every verification attempt logged

---

*Document Version: 1.0*
*Last Updated: 27 July 2026*
