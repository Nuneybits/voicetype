# VoiceType Design Document

**Date**: 2026-03-31
**Status**: Approved
**Summary**: A native macOS menu bar app for voice dictation that replaces Willow Voice. Fully local transcription via whisper.cpp, minimalist Swiss-inspired design, open-core business model.

---

## 1. Problem

Willow Voice charges $15/mo for push-to-talk dictation on macOS. The core functionality (speech-to-text + paste into active app) can be replicated locally for free using open-source models. Users deserve a fast, private, beautiful alternative.

## 2. Product Vision

VoiceType is a lightweight macOS menu bar utility. Press a hotkey, speak, and text appears in whatever app you're using. No accounts, no cloud dependency, no subscription required for core features.

**Target users**: Knowledge workers, prompt engineers, writers, developers, anyone who types a lot.

**Competitive positioning**: Faster, cheaper, more private than Willow. Open source builds trust. Native macOS app feels premium.

## 3. Architecture

### Tech Stack

- **Language**: Swift / SwiftUI
- **Transcription**: whisper.cpp via Swift package, large-v3-turbo model, CoreML-accelerated
- **Audio**: CoreAudio / AVAudioEngine, 16kHz PCM capture
- **Text injection**: Clipboard save, paste via CGEvent, clipboard restore
- **Persistence**: SQLite for transcription history
- **Updates**: Sparkle framework for auto-updates
- **Payments**: LemonSqueezy for Pro license keys

### Core Modules

```
┌─────────────────────────────────────────────────┐
│                   VoiceType                      │
│               macOS Menu Bar App                 │
│                  (SwiftUI)                       │
├─────────────────────────────────────────────────┤
│                                                  │
│  ┌──────────┐  ┌───────────┐  ┌──────────────┐ │
│  │ Hotkey   │  │ Audio     │  │ Transcription│ │
│  │ Listener │─▶│ Capture   │─▶│ Engine       │ │
│  │          │  │ (CoreAudio)│  │ (whisper.cpp)│ │
│  └──────────┘  └───────────┘  └──────┬───────┘ │
│                                       │         │
│                                       ▼         │
│                              ┌──────────────┐   │
│                              │ Text Output  │   │
│                              │ Router       │   │
│                              └──────┬───────┘   │
│                                     │           │
│                          ┌──────────┼────────┐  │
│                          ▼          ▼        ▼  │
│                     ┌────────┐ ┌───────┐ ┌────┐│
│                     │Paste to│ │History│ │Pro ││
│                     │Active  │ │Log    │ │AI  ││
│                     │App     │ │       │ │Mode││
│                     └────────┘ └───────┘ └────┘│
│                                                  │
├─────────────────────────────────────────────────┤
│  Settings │ Onboarding │ Sparkle Auto-Update     │
└─────────────────────────────────────────────────┘
```

1. **HotkeyManager** — Registers global keyboard shortcuts via CGEvent taps. Handles both hold-to-talk and toggle modes. Detects short press (toggle) vs. long press (hold-to-talk) with a 300ms threshold.

2. **AudioCapture** — CoreAudio/AVFoundation captures microphone input. Streams PCM audio at 16kHz (Whisper's native sample rate). Shows real-time audio level in menu bar indicator.

3. **TranscriptionEngine** — whisper.cpp compiled as a Swift package. Runs inference on Apple's Neural Engine/GPU via CoreML. Model file (~80MB for large-v3-turbo) downloaded on first launch, stored in `~/Library/Application Support/VoiceType/`.

4. **TextInjector** — Takes transcribed text, saves current clipboard, copies text to clipboard, simulates Cmd+V via CGEvent, restores original clipboard after brief delay. Works universally across all macOS apps.

5. **HistoryStore** — SQLite database storing transcriptions with timestamps and source app name. Free tier: last 10. Pro: unlimited with full-text search.

6. **AIPolishEngine** (Pro) — Pipes transcription through local LLM (Ollama/llama.cpp) or Claude API for grammar/style polish. User chooses local vs. cloud in settings.

### Data Flow

```
User holds ⌥Space
       │
       ▼
CGEvent tap (300ms gate: short press = toggle, long press = hold)
       │
       ▼
CoreAudio begins 16kHz PCM capture (ring buffer, 30s max)
       │  User releases key (or silence detected after 2s)
       ▼
whisper.cpp CoreML inference (200-500ms for 10s of speech)
       │
       ▼
Post-process: trim whitespace, apply auto-punctuation
       │
       ├──▶ Clipboard save → paste → restore → text appears in active app
       └──▶ SQLite history log (app name, timestamp, text)
```

### Performance Targets

| Metric | Target |
|---|---|
| Hotkey to recording starts | <50ms |
| End of speech to text appears | <800ms |
| Memory usage (idle) | <25MB |
| Memory usage (recording) | <150MB |
| CPU idle | ~0% |
| Battery impact | Negligible |

The whisper model stays loaded for 10 seconds after each use, then unloads. Re-loading takes ~300ms on Apple Silicon.

## 4. Visual Design

### Design Language

- **Typography**: SF Pro (macOS system font). Clean, Helvetica-lineage, renders perfectly at all sizes.
- **Aesthetic**: Swiss minimalism. No chrome, no visual clutter. Information density is zero when idle.
- **Animation budget**: Two animations only. Recording pulse and transcription-complete fade. Nothing gratuitous.

### Color Palette

| Token | Value | Usage |
|---|---|---|
| Background | #1A1A1A | Near-black base |
| Surface | #2A2A2A | Cards, panels |
| Text | #F5F5F5 | Primary text |
| Text Muted | #8A8A8A | Secondary text |
| Accent | #4A9EFF | Recording indicator, active states |
| Recording | #FF3B30 | Red pulse when recording |
| Success | #34C759 | Transcription complete flash |

Follows macOS system appearance (light/dark) automatically.

### Menu Bar States

| State | Icon | Behavior |
|---|---|---|
| Idle | Monochrome mic (SF Symbol: mic.fill) | Blends into menu bar |
| Recording | Accent-colored mic with pulse | Unmistakeable: "I'm listening" |
| Transcribing | Three-dot animation | Brief, typically <1s |
| Done | Green checkmark | Fades back to idle after 1s |

### Menu Bar Dropdown

Shows:
- On/off toggle
- "Time saved" stat line
- Recent transcriptions (preview, source app, timestamp, copy button)
- Hotkey hints (teaches interaction without a tutorial)
- Settings and Quit

### Settings Window

Single scrollable SwiftUI Form with grouped sections:
- **General**: Hotkey, mode (hold/toggle/both), launch at login
- **Transcription**: Language, model, auto-punctuation toggle
- **AI Polish** (Pro): Provider (local/cloud), style setting
- **About**: Version, update check, license status

No tabs, no sidebar. Everything fits in one view.

### Onboarding

Three screens only. No account creation. No email capture.

1. **Welcome**: "Dictate anywhere on your Mac."
2. **Try it**: Live demo — user holds hotkey, speaks, sees text. Requests mic permission in context. Requests accessibility permission with clear explanation.
3. **Ready**: Confirms hotkey, starts the app.

Total time to value: under 30 seconds.

## 5. Engagement & Growth

### "Time Saved" Counter

Estimates time saved based on words dictated vs. average typing speed (40 WPM). Displayed in menu bar dropdown. Reinforces habit, creates share moments, justifies Pro.

### Share Cards

At milestones, users can generate a minimal dark card showing their stats (words dictated, time saved) with the VoiceType URL. Designed to be screenshot-worthy for social sharing. No referral codes or gimmicks.

### Milestone Notifications

Rare, warm, native macOS notifications at key moments:
- First dictation
- 100 dictations
- 1 hour saved
- 1,000 dictations

Copy is brief and human, not corporate.

### Invisible Polish (Stickiness)

- **Sound design**: Soft click on record start, gentle whoosh on text inject. Disableable.
- **Clipboard harmony**: Saves and restores clipboard around every paste.
- **Smart paste format**: Strips punctuation corrections in code editors, pastes as plain text in rich editors.
- **Instant replay**: Cmd+Z undoes paste; double-tap hotkey re-opens last transcription for editing.
- **Smart silence detection**: Recording auto-stops after 2s silence in toggle mode.
- **Graceful offline**: Everything works without internet, always.
- **App-aware context**: Detects active app, shows in history. No setup required.

## 6. Business Model

### Pricing: Open Core

| | Free | Pro ($8/mo) |
|---|---|---|
| Unlimited dictation | Yes | Yes |
| Hold-to-talk + toggle | Yes | Yes |
| Auto-punctuation | Yes | Yes |
| History | Last 10 | Unlimited + search |
| Languages | 1 | All Whisper-supported |
| AI polish mode | No | Yes |
| Per-app profiles | No | Yes |
| Custom vocabulary | No | Yes |
| Priority support | No | Yes |

- Free tier is generous. No account required. No time limits.
- Annual option: $64/yr ($5.33/mo).
- Undercuts Willow by ~50%.
- Pure margin since everything runs locally.

### Payments & Licensing

LemonSqueezy handles payments, license keys, receipts. No backend required. License key validated once on activation, stored locally. App works offline forever after activation. No phone-home DRM.

### Distribution

- **GitHub**: Open source (MIT license). README with GIF demo.
- **Website**: voicetype.app with polished .dmg download.
- **Auto-updates**: Sparkle framework for non-App Store distribution.

### Launch Strategy (Zero Budget)

1. Hacker News "Show HN" post
2. Reddit: r/macapps, r/productivity, r/opensource
3. ProductHunt launch
4. GitHub README with 30-second GIF demo
5. Organic social proof via share cards and milestone notifications

### Growth Flywheel

Open source on GitHub → devs find it, star it, blog about it → non-technical users find the website → download .dmg → love the product → share stats cards on social → more users arrive → cycle repeats.

## 7. Project Structure

```
VoiceType/
├── VoiceType.xcodeproj
├── VoiceType/
│   ├── App/
│   │   ├── VoiceTypeApp.swift          # App entry, menu bar setup
│   │   ├── AppState.swift              # Central state management
│   │   └── AppDelegate.swift           # Lifecycle, permissions
│   ├── Core/
│   │   ├── HotkeyManager.swift         # Global hotkey registration
│   │   ├── AudioCapture.swift          # CoreAudio mic recording
│   │   ├── TranscriptionEngine.swift   # whisper.cpp wrapper
│   │   ├── TextInjector.swift          # Clipboard save/paste/restore
│   │   └── ModelManager.swift          # Download, cache, load models
│   ├── Features/
│   │   ├── History/
│   │   │   ├── HistoryStore.swift      # SQLite persistence
│   │   │   └── HistoryView.swift       # Recent transcriptions list
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift      # Settings window
│   │   │   └── HotkeyRecorder.swift    # Custom key recorder
│   │   ├── Onboarding/
│   │   │   └── OnboardingView.swift    # 3-screen first launch
│   │   ├── Stats/
│   │   │   ├── StatsTracker.swift      # Time saved calculations
│   │   │   └── ShareCardView.swift     # Shareable stats image
│   │   └── Pro/
│   │       ├── LicenseManager.swift    # LemonSqueezy validation
│   │       └── AIPolishEngine.swift    # LLM integration
│   ├── UI/
│   │   ├── MenuBarView.swift           # Dropdown content
│   │   ├── RecordingIndicator.swift    # Menu bar icon states
│   │   └── DesignSystem.swift          # Colors, fonts, spacing
│   └── Resources/
│       ├── Assets.xcassets             # App icon, SF Symbols
│       └── Sounds/                     # Click, whoosh (optional)
├── WhisperKit/                         # whisper.cpp Swift package
├── Tests/
│   ├── HotkeyManagerTests.swift
│   ├── TranscriptionEngineTests.swift
│   └── TextInjectorTests.swift
├── docs/
│   └── plans/
├── README.md
├── LICENSE                             # MIT
└── Makefile                            # build, sign, notarize, dmg
```

## 8. Key Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Accessibility permission is confusing for users | Clear explanation during onboarding, link to help article |
| whisper.cpp model is 80MB download | Download on first launch with progress bar, not bundled in .dmg |
| Clipboard restore timing | Configurable delay (default 100ms), test across slow apps |
| Apple Silicon only for CoreML | Fallback to CPU inference on Intel Macs (slower but functional) |
| macOS updates break CGEvent taps | Monitor macOS betas, maintain compatibility layer |

## 9. Future Considerations (Not in v1)

- Windows/Linux port (separate codebase or Tauri)
- Otter AI-style long-form transcription tool (separate product, shared whisper.cpp core)
- Custom fine-tuned Whisper models for specialized vocabularies
- Team/enterprise tier with shared custom vocabularies
