# Eco-Giants ZOU — DEMO QR CODES

Print these QR codes and place them on real bins for the hackathon demo.

## QR Code Format
```
EG_{BIN_ID}_{CATEGORY}_{TIMESTAMP}_{CHECKSUM}

Example: EG_BIN001_REC_1722100000_A3F7
```

## Demo Codes

### 1. Main Library — Recyclable
**Data:** `EG_BIN001_REC_1722100000_A3F7`
- Bin: Main Library - Floor 1
- Category: Recyclable (plastic, paper, glass, metal, cardboard)

### 2. Student Center — Organic
**Data:** `EG_BIN002_ORG_1722100000_B4E8`
- Bin: Student Center
- Category: Organic (food waste, compostable)

### 3. IT Building — E-Waste
**Data:** `EG_BIN003_EWA_1722100000_C5D9`
- Bin: IT Building
- Category: E-Waste (batteries, electronics, cables)

### 4. Student Center — General
**Data:** `EG_BIN002_GEN_1722100000_D6EA`
- Bin: Student Center
- Category: General (non-recyclable, non-hazardous)

### 5. Main Library — Hazardous
**Data:** `EG_BIN001_HAZ_1722100000_E7FB`
- Bin: Main Library
- Category: Hazardous (chemicals, batteries, sharps)

## How to Generate

Use any QR code generator online:
1. Go to https://www.qr-code-generator.com/
2. Enter the QR data string above
3. Download as PNG
4. Print at 5cm x 5cm minimum

Or generate programmatically:

```python
import qrcode

qr = qrcode.make("EG_BIN001_REC_1722100000_A3F7")
qr.save("qr_bin001_rec.png")
```

## Placement Tips

- Print on waterproof/sticker paper
- Minimum 5cm x 5cm for reliable scanning
- Place at eye level on each bin
- Ensure good lighting around the QR area

---
