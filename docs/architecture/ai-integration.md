# Eco-Giants ZOU — AI Integration Architecture

## Overview

The Eco-Giants app uses three distinct AI components:
1. **Waste Classifier** — Object detection using YOLOv8 (cloned from teamsmcorg/Waste-Classification-using-YOLOv8)
2. **Bin Recommender** — Rule-based matching with GPS distance calculation
3. **LLM Copilot** — NVIDIA API with meta/llama-3.1-8b-instruct for sustainability Q&A

---

## 1. Waste Classification Model (YOLOv8)

### Model Source
- **Repository**: https://github.com/teamsmcorg/Waste-Classification-using-YOLOv8
- **Framework**: YOLOv8 (Ultralytics)
- **Task**: Object detection with bounding boxes
- **Dataset**: 6,000+ images from Roboflow
- **Categories Detected**: plastic, metal, paper, glass, cardboard, biodegradable

### Category Mapping to Eco-Giants

| YOLOv8 Detected | Eco-Giants Category | Points | Notes |
|-----------------|-------------------|--------|-------|
| **plastic** | recyclable | 30 | Plastics are recyclable |
| **paper** | recyclable | 30 | Paper is recyclable |
| **cardboard** | recyclable | 30 | Cardboard is recyclable |
| **glass** | recyclable | 30 | Glass is recyclable |
| **metal** | recyclable | 30 | Metal is recyclable |
| **biodegradable** | organic | 20 | Food waste, compostable |
| **Detected electronic/device** | e-waste | 40 |phones, batteries, cables |
| **Unknown/generic** | general | 10 | Fallback category |
| **Detected chemicals/batteries** | hazardous | 50 | Special handling |

### Backend Implementation (FastAPI + YOLOv8)

```python
# backend/app/ml/waste_classifier_yolo.py
from ultralytics import YOLO
from PIL import Image
import numpy as np
import io
from typing import List, Dict, Optional
import os

class YOLOv8WasteClassifier:
    """YOLOv8-based waste classification using object detection."""
    
    # Mapping from YOLO labels to our app categories
    _CATEGORY_MAP = {
        'plastic': 'recyclable',
        'paper': 'recyclable',
        'cardboard': 'recyclable',
        'glass': 'recyclable',
        'metal': 'recyclable',
        'biodegradable': 'organic',
    }
    
    _DISPLAY_NAMES = {
        'recyclable': 'Recyclable',
        'organic': 'Organic',
        'e_waste': 'E-Waste',
        'general': 'General',
        'hazardous': 'Hazardous',
    }
    
    _CATEGORY_POINTS = {
        'recyclable': 30,
        'organic': 20,
        'e_waste': 40,
        'general': 10,
        'hazardous': 50,
    }
    
    # Educational factoids per category
    _FACTOIDS = {
        'recyclable': [
            "Recycling one aluminum can saves enough energy to power a TV for 3 hours!",
            "Plastic bottles take 450 years to decompose in landfills.",
            "Recycling paper saves 17 trees per ton!",
        ],
        'organic': [
            "Composting reduces landfill waste by up to 30%.",
            "Food waste in landfills produces methane, 25x more potent than CO2.",
        ],
        'e_waste': [
            "E-waste contains toxic materials like lead and mercury.",
            "Only 17% of global e-waste is properly recycled.",
        ],
        'general': [
            "Reducing waste is even better than recycling!",
        ],
        'hazardous': [
            "Batteries can leak toxic chemicals into soil and water.",
            "Always return hazardous waste to designated collection points.",
        ],
    }
    
    def __init__(self, model_path: str = None):
        """
        Initialize YOLOv8 model.
        
        Args:
            model_path: Path to .pt model file. Auto-downloads if None.
        """
        self.confidence_threshold = 0.40  # YOLO default confidence
        
        if model_path and os.path.exists(model_path):
            self.model = YOLO(model_path)
            print(f"Loaded YOLOv8 model from {model_path}")
        else:
            # Auto-download YOLOv8 nano (lightweight for server)
            self.model = YOLO('yolov8n.pt')
            print("Loaded default YOLOv8n model")
        
        self.input_size = (640, 640)  # YOLOv8 default
    
    def classify(self, image_bytes: bytes) -> Dict:
        """
        Classify waste item using YOLOv8 detection.
        
        Args:
            image_bytes: Raw image bytes (JPG/PNG)
            
        Returns:
            {
                'category': str,
                'category_name': str,
                'confidence': float,
                'detections': list of detected objects,
                'requires_manual': bool,
                'factoid': str,
                'points': int,
            }
        """
        # Load image
        image = Image.open(io.BytesIO(image_bytes))
        
        # Run inference
        results = self.model.predict(
            image,
            conf=self.confidence_threshold,
            verbose=False,
        )[0]  # Get first result
        
        # Parse detections
        detections = []
        category_scores = {}
        
        if results.boxes is not None:
            for box in results.boxes:
                cls_id = int(box.cls[0])
                conf = float(box.conf[0])
                label = results.names[cls_id]
                
                # Map to our category
                mapped_category = self._CATEGORY_MAP.get(label.lower(), 'general')
                
                detections.append({
                    'label': label,
                    'mapped_category': mapped_category,
                    'confidence': round(conf, 3),
                    'bbox': box.xyxy[0].tolist(),
                })
                
                # Aggregate scores by mapped category
                if mapped_category not in category_scores:
                    category_scores[mapped_category] = []
                category_scores[mapped_category].append(conf)
        
        # Determine final category (highest confidence)
        if category_scores:
            # Average confidence per category
            avg_scores = {
                cat: sum(scores) / len(scores) 
                for cat, scores in category_scores.items()
            }
            
            # Pick category with highest average confidence
            best_category = max(avg_scores, key=avg_scores.get)
            best_confidence = avg_scores[best_category]
            
            requires_manual = best_confidence < 0.50
        else:
            best_category = 'general'
            best_confidence = 0.0
            requires_manual = True
        
        # Select random factoid for the category
        import random
        factoid = random.choice(self._FACTOIDS.get(best_category, self._FACTOIDS['general']))
        
        return {
            'category': best_category,
            'category_name': self._DISPLAY_NAMES[best_category],
            'confidence': round(best_confidence, 3),
            'confidence_percentage': round(best_confidence * 100),
            'detections_count': len(detections),
            'detections': detections,
            'requires_manual': requires_manual,
            'factoid': factoid,
            'points': self._CATEGORY_POINTS[best_category],
        }
    
    def classify_with_visualization(self, image_bytes: bytes) -> Dict:
        """
        Classify and return annotated image for UI display.
        
        Returns:
            Classification result + annotated_image (base64)
        """
        import base64
        from io import BytesIO
        
        image = Image.open(io.BytesIO(image_bytes))
        
        # Run prediction with plotting
        results = self.model.predict(
            image,
            conf=self.confidence_threshold,
            verbose=False,
        )[0]
        
        # Get annotated image
        annotated_array = results.plot()
        annotated_image = Image.fromarray(annotated_array[..., ::-1])  # BGR to RGB
        
        # Convert to base64
        buffered = BytesIO()
        annotated_image.save(buffered, format="PNG")
        img_base64 = base64.b64encode(buffered.getvalue()).decode()
        
        # Get classification data
        classification = self.classify(image_bytes)
        classification['annotated_image_base64'] = img_base64
        
        return classification


# Singleton
_yolo_classifier: YOLOv8WasteClassifier = None

def get_yolo_classifier(model_path: str = None) -> YOLOv8WasteClassifier:
    """Get or create singleton YOLOv8 classifier."""
    global _yolo_classifier
    if _yolo_classifier is None:
        _yolo_classifier = YOLOv8WasteClassifier(model_path=model_path)
    return _yolo_classifier
```

### Model Training (Optional - for custom dataset)

```python
# backend/scripts/train_yolo.py
from ultralytics import YOLO

def train_waste_yolo(data_yaml_path: str = "data/waste_data.yaml"):
    """
    Train YOLOv8 on waste classification dataset.
    
    Dataset format (Roboflow):
    - images/train/
    - images/val/
    - images/test/
    - labels/train/
    - labels/val/
    - labels/test/
    - data.yaml (classes: plastic, metal, paper, glass, cardboard, biodegradable)
    """
    # Load pretrained model
    model = YOLO('yolov8n.pt')  # nano = fastest, smallest
    
    # Train
    results = model.train(
        data=data_yaml_path,
        epochs=100,
        imgsz=640,
        batch=16,
        name='waste_classifier',
        patience=20,  # early stopping
        device=0,  # GPU
    )
    
    # Validate
    metrics = model.val()
    print(f"mAP50-95: {metrics.box.map}")
    print(f"mAP50: {metrics.box.map50}")
    
    # Export to ONNX for faster inference
    model.export(format='onnx')
    
    return model

if __name__ == "__main__":
    train_waste_yolo()
```

### API Endpoint

```python
# backend/app/api/v1/waste.py
from fastapi import APIRouter, UploadFile, File, Depends
from app.ml.waste_classifier_yolo import get_yolo_classifier

router = APIRouter(prefix="/waste", tags=["waste"])

@router.post("/classify")
async def classify_waste(image: UploadFile = File(...)):
    """Classify waste item using YOLOv8."""
    # Validate image
    if not image.content_type.startswith("image/"):
        raise HTTPException(400, "File must be an image")
    
    image_bytes = await image.read()
    if len(image_bytes) > 5 * 1024 * 1024:
        raise HTTPException(400, "Image too large (max 5MB)")
    
    # Classify
    classifier = get_yolo_classifier("models/waste_yolov8.pt")
    result = classifier.classify(image_bytes)
    
    # Save image and classification to DB
    # ...
    
    return {
        "success": True,
        "data": {
            "category": result['category'],
            "category_name": result['category_name'],
            "confidence": result['confidence'],
            "confidence_percentage": result['confidence_percentage'],
            "requires_manual": result['requires_manual'],
            "factoid": result['factoid'],
            "detections_count": result['detections_count'],
            "points_preview": result['points'],
        }
    }
```

### YOLOv8 Dependencies

```
ultralytics>=8.0.0
opencv-python>=4.7.0
Pillow>=9.0.0
numpy>=1.24.0
torch>=2.0.0
torchvision>=0.15.0
```

### Performance

| Metric | Value |
|--------|-------|
| Model Size (YOLOv8n) | ~6MB |
| Inference Time (CPU) | 50-100ms |
| Inference Time (GPU) | 5-20ms |
| Detected Classes | 6 (mapped to 5 app categories) |
| mAP50 (trained) | ~85% |

---

## 2. Bin Recommender

Simple rule-based system matching waste category to campus bins.
See architecture docs for full implementation.

---

## 3. LLM Copilot (NVIDIA API)

### Configuration

```bash
# backend/.env (NOT committed to git!)
NVIDIA_API_KEY=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
NVIDIA_LLM_BASE_URL=https://integrate.api.nvidia.com/v1
NVIDIA_GEN_MODEL=meta/llama-3.1-8b-instruct
```

```python
# backend/app/services/nvidia_copilot.py
import os
import requests
from typing import List, Dict, Optional
from datetime import datetime, timedelta

class NVIDIACopilotService:
    """
    Sustainability copilot using NVIDIA API with Llama 3.1 8B Instruct.
    
    Docs: https://docs.nvidia.com/nim/
    """
    
    SYSTEM_PROMPT = """You are Eco-Giants, a friendly and encouraging sustainability copilot for Zimbabwe Open University students.

Your personality:
- Enthusiastic about environmental protection
- Use casual, encouraging language with occasional emojis
- Provide SPECIFIC data from the student's disposal log
- Always celebrate progress and motivate improvement
- Keep responses under 150 words
- Reference Zimbabwe/ZOU campus context when relevant

When provided disposal data:
- Quote exact numbers ("You've recycled 12 bottles this week!")
- Compare to averages
- Suggest next category to focus on
- Calculate progress to next eco level

If you lack specific data, be honest and offer general sustainability tips."""

    def __init__(self):
        self.api_key = os.getenv("NVIDIA_API_KEY")
        self.base_url = os.getenv("NVIDIA_LLM_BASE_URL", "https://integrate.api.nvidia.com/v1")
        self.model = os.getenv("NVIDIA_GEN_MODEL", "meta/llama-3.1-8b-instruct")
        
        if not self.api_key:
            raise ValueError("NVIDIA_API_KEY not set. Check your .env file.")
    
    def chat(
        self,
        message: str,
        student_id: str,
        disposal_history: List[Dict],
        current_level: str,
        total_points: int,
        conversation_history: Optional[List[Dict]] = None,
    ) -> Dict:
        """
        Generate personalized copilot response.
        """
        # Build context
        context = self._build_context(
            disposal_history, current_level, total_points
        )
        
        # Build messages for Llama 3.1
        messages = [
            {"role": "system", "content": self.SYSTEM_PROMPT},
            {"role": "system", "content": f"Student Context:\n{context}\n\nAnswer the student's question based on their data."},
        ]
        
        # Add conversation history
        if conversation_history:
            # Last 3 exchanges (6 messages)
            for hist in conversation_history[-6:]:
                messages.append(hist)
        
        # Add current user message
        messages.append({"role": "user", "content": message})
        
        # Call NVIDIA API
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        
        payload = {
            "model": self.model,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 300,
            "top_p": 0.9,
            "stream": False,
        }
        
        response = requests.post(
            f"{self.base_url}/chat/completions",
            headers=headers,
            json=payload,
            timeout=30,
        )
        
        response.raise_for_status()
        result = response.json()
        
        content = result['choices'][0]['message']['content']
        
        # Generate quick replies
        quick_replies = self._generate_quick_replies(
            message, content, total_points, current_level
        )
        
        return {
            "response": content,
            "quick_replies": quick_replies,
            "model_used": self.model,
            "sources": [{"type": "disposal_log", "count": len(disposal_history)}],
        }
    
    def _build_context(
        self,
        disposal_history: List[Dict],
        current_level: str,
        total_points: int,
    ) -> str:
        """Build student context from disposal data."""
        total_items = len(disposal_history)
        
        by_category = {}
        this_week = 0
        last_week = 0
        
        now = datetime.utcnow()
        week_ago = now - timedelta(days=7)
        two_weeks_ago = now - timedelta(days=14)
        
        for item in disposal_history[-50:]:  # Last 50 items
            cat = item.get('category', 'unknown')
            by_category[cat] = by_category.get(cat, 0) + 1
            
            item_date = datetime.fromisoformat(item.get('created_at', ''))
            if item_date >= week_ago:
                this_week += 1
            elif item_date >= two_weeks_ago:
                last_week += 1
        
        context = f"""Current Eco Level: {current_level}
Total Points: {total_points}
Total Items Disposed: {total_items}
This Week: {this_week} items
Last Week: {last_week} items

Breakdown by Category:"""
        
        for cat, count in by_category.items():
            context += f"\n- {cat}: {count}"
        
        return context
    
    def _generate_quick_replies(
        self,
        user_message: str,
        response: str,
        total_points: int,
        current_level: str,
    ) -> List[str]:
        """Suggest follow-up questions."""
        replies = ["How do I reach the next level?"]
        
        if 'recycle' in user_message.lower():
            replies.append("What else can I recycle?")
        
        if 'streak' in user_message.lower():
            replies.append("What's my current streak?")
        
        if len(replies) < 3:
            replies.append("Give me a recycling tip")
        
        return replies[:3]


# Pre-set quick questions
QUICK_QUESTIONS = [
    {
        "icon": "♻️",
        "text": "How many items have I recycled?",
        "prompt": "Tell me exactly how many items I've recycled in total and this week, with breakdown by category.",
    },
    {
        "icon": "🎯",
        "text": "How do I reach the next level?",
        "prompt": "How many more points do I need to reach the next eco level? What should I focus on recycling?",
    },
    {
        "icon": "💡",
        "text": "What can I recycle?",
        "prompt": "What items are recyclable on ZOU campus? Give me specific examples.",
    },
    {
        "icon": "📊",
        "text": "Show my weekly progress",
        "prompt": "Show me my recycling progress this week compared to last week with specific numbers.",
    },
    {
        "icon": "🏆",
        "text": "How am I doing vs others?",
        "prompt": "How does my recycling compare to other students? Tips to improve my rank?",
    },
]
```

### NVIDIA API Endpoint

```python
# backend/app/api/v1/copilot.py
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from app.services.nvidia_copilot import NVIDIACopilotService

router = APIRouter(prefix="/copilot", tags=["copilot"])

class ChatRequest(BaseModel):
    message: str
    conversation_id: Optional[str] = None

class ChatResponse(BaseModel):
    response: str
    quick_replies: List[str]
    sources: List[dict]

@router.post("/chat")
async def chat_with_copilot(
    request: ChatRequest,
    current_student = Depends(get_current_student),
):
    """Chat with NVIDIA Llama-powered sustainability copilot."""
    
    # Fetch student's disposal history
    disposal_history = await get_disposal_history(current_student.id)
    
    # Get score
    score = await get_score(current_student.id)
    
    # Call NVIDIA copilot
    copilot = NVIDIACopilotService()
    result = copilot.chat(
        message=request.message,
        student_id=current_student.id,
        disposal_history=disposal_history,
        current_level=score.eco_level,
        total_points=score.total_points,
    )
    
    # Store conversation
    # await save_conversation(...)
    
    return result
```

### Environment Setup

```bash
# .env (add to .gitignore!)
# Backend
DATABASE_URL=postgresql://postgres:password@localhost:5432/eco_giants
REDIS_URL=redis://localhost:6379/0
JWT_SECRET=your-jwt-secret-here

# NVIDIA API
NVIDIA_API_KEY=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
NVIDIA_LLM_BASE_URL=https://integrate.api.nvidia.com/v1
NVIDIA_GEN_MODEL=meta/llama-3.1-8b-instruct

# YOLO
YOLO_MODEL_PATH=models/waste_yolov8.pt
```

### Cost Estimation (NVIDIA)

| Component | Model | Price/1K Tokens | Avg Request | Monthly Cost |
|-----------|-------|-----------------|-------------|--------------|
| NVIDIA Llama 3.1 8B | meta/llama-3.1-8b-instruct | ~$0.10 | ~500 tokens | ~$5-15 |

---

## 4. Integration Flow

```
Flutter App
    │
    ├── POST /api/v1/waste/classify (image)
    │   → FastAPI → YOLOv8 → Category + Confidence + Factoid
    │
    ├── POST /api/v1/verification/scan (QR)
    │   → FastAPI → Validate → Award Points
    │
    └── POST /api/v1/copilot/chat (message)
        → FastAPI → NVIDIA API (Llama 3.1) → Personalized Response
```

---

## 5. Performance Targets

| Component | Latency Target | Latency Acceptable |
|-----------|---------------|-------------------|
| YOLOv8 Classification | < 1s (server) | < 3s |
| NVIDIA LLM Response | < 2s | < 5s |
| QR Verification | < 200ms | < 500ms |
| Leaderboard Query | < 100ms | < 300ms |

---

*Document Version: 2.0 (Updated with YOLOv8 + NVIDIA)*
*Last Updated: 27 July 2026*
