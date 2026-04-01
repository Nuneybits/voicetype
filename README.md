# VoiceType

Press a key. Speak. Text appears. Anywhere on your Mac.

VoiceType is a native macOS menu bar app for voice dictation. Fully local, fully private, powered by [WhisperKit](https://github.com/argmaxinc/WhisperKit).

## Features

- **Hold-to-talk or toggle** — hold Option+Space to dictate, or tap to toggle recording
- **Works everywhere** — Gmail, Slack, Cursor, Notion, Terminal, any app
- **Fully local** — no cloud, no accounts, no data leaves your Mac
- **Fast** — sub-second transcription on Apple Silicon via CoreML
- **Lightweight** — ~25MB idle, native Swift/SwiftUI
- **Smart clipboard** — saves and restores your clipboard around every paste
- **Transcription history** — recent dictations with one-click copy
- **Time saved tracker** — see how much typing you've avoided

## Install

### Download

Download the latest `.dmg` from [Releases](https://github.com/voicetype/voicetype/releases).

### Build from source

Requires macOS 14+ and Swift 5.9+.

```bash
git clone https://github.com/voicetype/voicetype.git
cd voicetype
make build
make run
```

To create a distributable `.app` bundle:

```bash
make bundle
```

To create a `.dmg`:

```bash
make dmg
```

## Usage

1. Launch VoiceType — it lives in your menu bar
2. Press **Option+Space** and speak
3. Release the key — your words appear in the active app

**Hold-to-talk**: Hold the key while speaking, release when done.

**Toggle mode**: Tap once to start recording, tap again to stop.

The Whisper model (~800MB) downloads automatically on first use.

## Permissions

VoiceType needs two permissions:

- **Microphone** — to hear your voice
- **Accessibility** — to paste text into your apps

Both are requested during first launch.

## Tech Stack

- Swift / SwiftUI (native macOS menu bar app)
- [WhisperKit](https://github.com/argmaxinc/WhisperKit) — CoreML-accelerated Whisper inference
- [HotKey](https://github.com/soffes/HotKey) — global keyboard shortcuts
- SQLite — transcription history
- No Electron. No web views. No cloud.

## Contributing

Contributions welcome. Please open an issue before submitting a PR for non-trivial changes.

## License

[MIT](LICENSE)
