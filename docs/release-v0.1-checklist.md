# VoiceType v0.1 Release Checklist

## Product Scope

- Ship VoiceType as a local desktop dictation app with a floating capture pad.
- Do not market v0.1 as universal text insertion across every Mac app.
- Position automatic insertion, cleanup modes, and deeper workflow features as roadmap items.

## Release Blockers

- Confirm the app icon and Finder bundle presentation look correct on a clean machine.
- Decide whether to ship with ad-hoc signing for early testers or with a proper Developer ID signature for public release.
- If shipping publicly outside a trusted circle, notarize the `.app` and `.dmg`.
- Verify first-run onboarding on a machine that has never granted microphone permission.
- Verify model download behavior on a fresh install.

## Code And Product QA

- Test start and stop recording from the floating panel.
- Test the `Command+Shift+Space` hotkey from another app.
- Test batch mode and live preview mode.
- Test copy single block and copy full session.
- Test a long dictation session of at least 10 to 15 minutes.
- Confirm the menu bar state changes correctly: idle, recording, transcribing, done.
- Confirm recent history displays correctly after relaunch.

## Packaging

- Run `make bundle` to create `dist/VoiceType.app`.
- Run `make dmg` to create `dist/VoiceType.dmg`.
- Confirm the DMG contains both `VoiceType.app` and the `Applications` shortcut.
- Upload the DMG to GitHub Releases.
- Add release notes with scope, known limitations, and macOS version requirements.

## GitHub Launch Pack

- Clean README with accurate product positioning.
- One polished screenshot of the floating panel while recording.
- One screenshot of the menu bar dropdown.
- Short release summary for the GitHub release page.
- MIT license included.

## Website / Portfolio Assets

- Short product description: one sentence.
- Two screenshots or one short GIF.
- Download link to GitHub Releases.
- Source code link to GitHub.
- Short roadmap paragraph so the project reads as actively maintained.

## Decisions To Lock Before Publish

- Signing path:
  - Early preview: ad-hoc signed DMG for trusted users.
  - Public release: Developer ID signing plus notarization.
- Product promise:
  - `VoiceType v0.1` is a polished local dictation pad.
  - `VoiceType v0.2+` can expand toward automatic insertion.
- Distribution:
  - GitHub Releases only for the first launch.
  - Website links to the release, not a separate download host.

## Nice-To-Have After Launch

- Restore or redesign automatic insertion into the frontmost app.
- Add transcription cleanup modes: raw, clean, polished.
- Add export options like Markdown and append-to-file.
- Add proper launch-at-login implementation.
- Add notarization and auto-update infrastructure.
