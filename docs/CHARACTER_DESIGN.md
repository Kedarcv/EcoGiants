# Duolingo-Style Character Design System

## EcoBot Character Guide

This document outlines the design system for the EcoBot mascot, inspired by Duolingo's character design principles.

## Shape Language

### Primary Shapes
- **Circles**: Used for head, eyes, and joints - conveys friendliness
- **Rounded Rectangles**: Body and limbs with soft 20px+ corner radius
- **Curves**: All connections use smooth bezier curves, no sharp angles

### Proportions
- Head to body ratio: 1:1.3 (slightly larger head for cuteness)
- Eye size: 15% of head width
- Arm thickness: 12px stroke weight
- Leg length: 20% of total height

## Character Poses

### 1. Waving (Greeting)
**File**: `ecobot_waving.svg`
- One arm raised at 45° angle
- Big smile showing enthusiasm
- Use case: Welcome screens, initial greeting

### 2. Celebrating (Success)
**File**: `ecobot_celebrating.svg`
- Both arms raised in V-shape
- Jumping pose with bent legs
- Sparkles around head
- Use case: Correct answers, level ups, achievements

### 3. Listening (Attentive)
**File**: `ecobot_listening.svg`
- Hand cupped to ear
- Slightly tilted head
- Sound wave indicators
- Use case: When user is speaking, voice input active

### 4. Teaching (Explaining)
**File**: `ecobot_teaching.svg`
- One finger pointing up
- Confident stance with hand on hip
- Light bulb above head
- Use case: Explaining concepts, giving tips

## Color Palette

```dart
Primary Teal:    #2DD4BF
Secondary Green: #10B981
Dark Teal:       #0D9488
Accent Amber:    #F59E0B
Outline Dark:    #1F2937
Highlight White: #FFFFFF
```

## Animation Principles

### Bounce
- Duration: 600ms
- Curve: ease-in-out
- Amplitude: -10px vertical translation
- Use: Celebrating, waving poses

### Glow
- Duration: 1500ms
- Curve: ease-in-out
- Opacity: 0.3 ↔ 0.7
- Use: All states for magical feel

### Pulse (Listening)
- Duration: 1500ms
- Scale: 1.0 ↔ 1.3
- Use: Microphone active state

## Implementation Files

### SVG Assets
- `/workspace/assets/svgs/ecobot_waving.svg`
- `/workspace/assets/svgs/ecobot_celebrating.svg`
- `/workspace/assets/svgs/ecobot_listening.svg`
- `/workspace/assets/svgs/ecobot_teaching.svg`

### Flutter Widget
- `/workspace/lib/components/ecobot_character.dart`
  - `EcoBotCharacter` - Main character widget
  - `EcoBotFAB` - Floating action button variant
  - `EcoBotPose` enum for pose selection

### Usage Example

```dart
// In Live AI Screen
EcoBotCharacter(
  pose: EcoBotPose.listening,
  size: 180,
  animated: true,
)

// State-based pose switching
setState(() {
  _ecobotPose = EcoBotPose.teaching;
});
```

## Future Enhancements

### Additional Poses to Add
- [ ] Thinking (hand on chin)
- [ ] Pointing (directing attention)
- [ ] Holding recycling item
- [ ] Dancing (celebration variant)
- [ ] Sleeping (idle state)

### Lottie Animations
Consider converting SVG sequences to Lottie for:
- Smooth transitions between poses
- Complex animations (jumping, spinning)
- Particle effects (confetti, sparkles)

### Voice Synching
Future implementation could include:
- Mouth movement synced to TTS audio
- Eyebrow raises for emphasis
- Head tilts during conversation

## References
- Duolingo Design System: https://design.duolingo.com/
- Shape Language: https://design.duolingo.com/illustration/shape-language
- Character Design: https://design.duolingo.com/illustration/characters
