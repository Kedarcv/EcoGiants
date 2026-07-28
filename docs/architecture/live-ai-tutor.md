# Live AI Tutor Architecture

> Real-time AI tutor that can **see what the student sees** (via camera) and **talk back** (via TTS) using NVIDIA LLM.

---

## Overview

The Live AI Tutor adds a "face-to-face" learning mode to Eco-Giants. The student opens the Live AI screen, their camera feed is active, and they can ask EcoBot questions via text or quick prompts. EcoBot replies in real-time using NVIDIA's hosted Llama-3.1-8B model and speaks the response aloud via the device's TTS engine.

This creates an immersive, hands-on learning experience — the student can literally hold up a waste item to the camera and ask "What bin does this go in?"

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Eco-Giants App (Flutter)                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ Camera       │  │ Chat UI      │  │ TTS Engine       │  │
│  │ (camera pkg) │  │ (Stream+UI)  │  │ (flutter_tts)    │  │
│  └──────┬───────┘  └──────┬───────┘  └────────┬─────────┘  │
│         │                 │                    │            │
│  ┌──────▼─────────────────▼────────────────────▼─────────┐  │
│  │         LiveKitRoomManager (Flutter)                  │  │
│  │  • WebSocket signalling to LiveKit Cloud              │  │
│  │  • JWT token generation (client-side for demo)        │  │
│  │  • Delegates to NvidiaChatService for LLM replies     │  │
│  └────────────────────────┬───────────────────────────────┘  │
│                           │ SSE stream                       │
│                    ┌──────▼───────┐                          │
│                    │  LLM Request │                          │
│                    └──────┬───────┘                          │
└───────────────────────────┼──────────────────────────────────┘
                            │ HTTPS / SSE
              ┌─────────────▼─────────────┐
              │  NVIDIA API Cloud         │
              │  integrate.api.nvidia.com │
              │  model: llama-3.1-8b-ins  │
              └─────────────┬─────────────┘
                            │
              ┌─────────────▼─────────────┐
              │  LiveKit Cloud            │
              │  eco-giants-l8flnoop      │
              │  WebRTC rooms + relay     │
              └───────────────────────────┘
```

---

## Services

### 1. `livekit_config.dart`
Centralised secrets and endpoint constants.

| Constant | Value | Purpose |
|----------|-------|---------|
| `wsUrl` | `wss://eco-giants-l8flnoop.livekit.cloud` | LiveKit Cloud WSS endpoint |
| `apiKey` / `apiSecret` | `APIbTNp58i…` / `yDau9pZ3Q…` | JWT signing credentials |
| `NvidiaConfig.apiKey` | `nvapi-VAIZZEz…` | NVIDIA API key |
| `NvidiaConfig.baseUrl` | `https://integrate.api.nvidia.com/v1` | OpenAI-compatible completions endpoint |
| `NvidiaConfig.model` | `meta/llama-3.1-8b-instruct` | Default model |

> ⚠️ **Security Note:** The API keys are hardcoded for the hackathon demo. In production, move token generation and API calls to a backend proxy so secrets never ship in the app binary.

### 2. `nvidia_chat_service.dart`
Handles streaming chat completions via SSE (Server-Sent Events).

- **Endpoint:** `POST /v1/chat/completions`
- **Streaming:** `stream: true` yields token-by-token text
- **History:** Maintains in-memory conversation context
- **System prompt:** Defines EcoBot's persona, rules, and scope (waste-sorting tutor only)

```dart
final stream = chatService.sendMessage('How do I recycle batteries?');
await for (final chunk in stream) {
  print(chunk); // "Batteries go in..."
}
```

### 3. `livekit_room_manager.dart`
Manages the LiveKit room lifecycle, camera, TTS synthesis, and AI delegation.

| Method | What it does |
|--------|--------------|
| `connect()` | Generates JWT, opens WebSocket signalling, sets state to connected |
| `disconnect()` | Closes WS, stops TTS |
| `askAiTutor(text)` | Streams the user's question to NVIDIA LLM, yields text chunks, then speaks the full reply via TTS |
| `speak(text)` | Synthesises speech via `flutter_tts` (rate 0.48, pitch 1.05 for warm student-friendly tone) |
| `sendTextMessage(text)` | Sends a raw message over the WS signalling channel |

---

## UI: `LiveAiScreen`

### Layout
```
┌─────────────────────────────┐
│ AppBar: EcoBot Live Tutor   │
│ [status chip] [call button] │
├─────────────────────────────┤
│ Camera Preview (220px)      │
│ "EcoBot can see this"       │
├─────────────────────────────┤
│ Quick Prompt Chips (horiz)  │
│ "What bin does this go in?" │
├─────────────────────────────┤
│ Chat Bubbles (scrollable)   │
│ User → right, teal bubble   │
│ EcoBot → left, white bubble │
├─────────────────────────────┤
│ Typing indicator (animated) │
├─────────────────────────────┤
│ Input bar + send button     │
└─────────────────────────────┘
```

### Quick Prompts
Students can tap chips instead of typing:
- 📦 What bin does this go in?
- ♻️ Why is recycling important?
- 🔋 How do I dispose of batteries?
- 🍎 Can I compost this?
- 🌍 Fun fact about waste!

### Interactions
1. **Tap call button** → Connects to LiveKit room + shows camera preview
2. **Type or tap prompt** → Message appears in chat, AI responds with streamed text + TTS
3. **Flip camera** → Switches front/back camera to show the AI different items
4. **Tap call button again** → Disconnects

---

## Permissions

### Android (`AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-feature android:name="android.hardware.camera" />
```

### iOS (`Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for the AI tutor to see waste items.</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app uses the microphone so the AI tutor can hear your questions.</string>
```

Both permissions are requested at runtime via the `permission_handler` package before camera initialisation.

---

## Dependencies Added

| Package | Version | Purpose |
|---------|---------|---------|
| `http` | ^1.2.2 | HTTPS requests to NVIDIA API |
| `flutter_tts` | ^4.2.2 | Text-to-speech synthesis |
| `permission_handler` | ^11.3.1 | Runtime camera/mic permission requests |

---

## Future Enhancements

| Feature | Approach |
|---------|----------|
| **Real WebRTC video** | Replace WebSocket signalling with `livekit_client` package once on pub.dev |
| **Speech-to-Text input** | Integrate `speech_to_text` package so students can talk instead of type |
| **Backend token proxy** | Move JWT + API key generation to a Cloud Function / AWS Lambda |
| **Multi-student rooms** | Use LiveKit room `maxParticipants` for group tutoring sessions |
| **Screen capture** | Instead of camera, stream the app's UI for remote debugging / demos |

---

## Files
- `lib/services/livekit_config.dart` — Constants
- `lib/services/nvidia_chat_service.dart` — LLM streaming client
- `lib/services/livekit_room_manager.dart` — Room lifecycle + TTS
- `lib/screens/LiveAiScreen.dart` — UI
- `lib/routes.dart` — Route registration
- `lib/screens/HomeScreen.dart` — Quick-action button added

*Document Version: 1.0*
