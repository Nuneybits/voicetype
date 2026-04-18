# VoiceType

VoiceType is a local voice-to-text app for Mac.

It is built for writers, journalists, researchers, founders, and anyone who sometimes thinks more clearly out loud than at a keyboard. Press record, speak naturally, and VoiceType turns your words into text on your computer without sending your audio to a remote server.

This first public release is intentionally focused. VoiceType `v0.1` is a fast, lightweight dictation tool with a floating capture pad. It is designed to be simple, private, and useful from the first minute.

## What VoiceType Is For

VoiceType helps you:

- draft articles, notes, outlines, and memos by speaking
- capture long thoughts before they disappear
- reduce the friction of typing when you would rather talk
- keep control of your audio and transcripts on your own machine

In plain English: it is a writing tool for people who want speech-to-text to feel fast, clean, and calm.

## Why This Exists

There are already dictation tools on the market, but many of them are expensive, cloud-dependent, or overloaded with features. VoiceType takes a different approach.

It is:

- native to macOS
- local-first and privacy-respecting
- built to feel lightweight instead of bloated
- shaped by a writer's workflow, not just an engineer's demo

## What Ships In v0.1

VoiceType `v0.1` includes:

- local transcription on macOS using WhisperKit
- a menu bar app that stays out of the way until you need it
- a floating notepad for recording and collecting text blocks
- a global hotkey: `Command + Shift + Space`
- optional live transcription preview while you speak
- session word count and recent transcription history
- a shareable `.app` and `.dmg` for installation

## Coming Soon

Planned future improvements include:

- direct insertion into the app you are actively using
- cleanup modes for raw, clean, and polished transcription
- better export workflows for writers and journalists
- longer-session handling beyond the current in-memory limit
- launch-at-login and additional desktop polish

## Download

The simplest way to get VoiceType is to download the latest `.dmg` from GitHub Releases.

After downloading:

1. Open the `.dmg` file.
2. Drag `VoiceType.app` into the `Applications` folder.
3. Open `Applications` and launch VoiceType.

If macOS warns you because the app is from the internet, that is expected for this early release. The warning is caused by Apple security checks on unsigned or not-yet-notarized apps, not by the DMG itself.

To open it:

1. In `Applications`, hold `Control` and click `VoiceType.app`
2. Choose `Open`
3. Click `Open` again in the confirmation dialog

If needed, you can also go to `System Settings > Privacy & Security` and choose `Open Anyway`.

## Install Notes

For most people, the correct install flow is:

1. Download the latest `.dmg`
2. Open it
3. Drag `VoiceType.app` into `Applications`
4. Open `Applications`
5. Control-click `VoiceType`
6. Choose `Open`
7. Click `Open` again

After the first successful launch, you should be able to open the app normally.

## Install From Source

If you want to build VoiceType yourself, you will need:

- macOS 14 or newer
- Xcode / Swift toolchain

Then run:

```bash
git clone https://github.com/voicetype/voicetype.git
cd voicetype
make build
make run
```

To create a distributable app bundle:

```bash
make bundle
```

To create a distributable DMG:

```bash
make dmg
```

## How To Use VoiceType

VoiceType is meant to be straightforward.

1. Launch VoiceType. It will live in your menu bar.
2. Open the floating notepad from the menu bar.
3. Press `Command + Shift + Space` or click the record button.
4. Speak naturally.
5. Press the hotkey again, or click stop, when you are finished.
6. Copy one text block or copy the full session into the document you are writing.

On first use, VoiceType will prepare its speech model. That download can take a moment. After that, dictation should feel much faster.

## Permissions

VoiceType needs:

- **Microphone access** so it can hear your speech

Future versions that insert text directly into other apps may also require:

- **Accessibility access** so macOS allows the app to interact with the frontmost application

## Product Scope

VoiceType `v0.1` is a polished local dictation pad.

It does **not** yet try to automatically insert text into every app on your Mac. That feature may come later. For now, the goal is reliability, privacy, and a clean experience for recording and copying text.

## Tech Stack

- Swift / SwiftUI
- [WhisperKit](https://github.com/argmaxinc/WhisperKit)
- [HotKey](https://github.com/soffes/HotKey)
- SQLite for history

No Electron. No web view. No cloud account required.

## Contributing

Contributions are welcome. If you want to propose a substantial change, please open an issue first so the direction stays coherent.

## License

[MIT](LICENSE)
