# VoiceType Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a native macOS menu bar app for voice dictation that replaces Willow Voice — fully local transcription via WhisperKit, minimalist design, open-core business model.

**Architecture:** Swift/SwiftUI menu bar app using MenuBarExtra (.window style). WhisperKit for CoreML-accelerated transcription. HotKey for global keyboard shortcuts with hold-to-talk and toggle modes. Text injected into active apps via clipboard + CGEvent Cmd+V simulation.

**Tech Stack:**
- Swift 5.9+ / SwiftUI / macOS 14+
- WhisperKit (SPM: `https://github.com/argmaxinc/WhisperKit.git`)
- HotKey (SPM: `https://github.com/soffes/HotKey`)
- KeyboardShortcuts (SPM: `https://github.com/sindresorhus/KeyboardShortcuts`)
- Sparkle (SPM: `https://github.com/sparkle-project/Sparkle`)
- SQLite via Swift's built-in `sqlite3` C library
- LemonSqueezy for Pro license keys (future)

---

## Task 1: Create Xcode Project & Configure Dependencies

**Files:**
- Create: `VoiceType/VoiceType.xcodeproj` (via Xcode CLI)
- Create: `VoiceType/VoiceType/VoiceTypeApp.swift`
- Create: `VoiceType/VoiceType/Info.plist`

**Step 1: Create the Xcode project**

```bash
cd /Users/michaelnunez/Desktop/NEW-experiment-1
mkdir -p VoiceType
cd VoiceType
```

Create the project using Xcode's `xcodebuild` or manually. Since we need precise SPM configuration, create a `Package.swift` at the workspace root to manage dependencies, then create the Xcode project structure manually:

```
VoiceType/
├── Package.swift
├── Sources/
│   └── VoiceType/
│       ├── App/
│       │   └── VoiceTypeApp.swift
│       └── Resources/
│           └── Info.plist
└── Tests/
    └── VoiceTypeTests/
        └── VoiceTypeTests.swift
```

**Step 2: Create Package.swift**

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VoiceType",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "VoiceType", targets: ["VoiceType"]),
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0"),
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.1"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "VoiceType",
            dependencies: [
                "WhisperKit",
                "HotKey",
                "KeyboardShortcuts",
                "Sparkle",
            ],
            path: "Sources/VoiceType",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "VoiceTypeTests",
            dependencies: ["VoiceType"],
            path: "Tests/VoiceTypeTests"
        ),
    ]
)
```

**Note:** We may need to switch to an Xcode project (`.xcodeproj`) instead of SPM executable if we need full control over entitlements, Info.plist embedding, and app bundle structure. If `swift build` works cleanly with all dependencies, we stay with SPM. If not (common with WhisperKit's CoreML models), we generate an Xcode project with `swift package generate-xcodeproj` or create one manually. Evaluate after Step 3.

**Step 3: Create minimal app entry point**

```swift
// Sources/VoiceType/App/VoiceTypeApp.swift
import SwiftUI

@main
struct VoiceTypeApp: App {
    var body: some Scene {
        MenuBarExtra("VoiceType", systemImage: "mic.fill") {
            Text("VoiceType is running")
                .padding()
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.window)
    }
}
```

**Step 4: Create Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>LSUIElement</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>VoiceType needs microphone access to transcribe your speech.</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>VoiceType needs accessibility access to type text into your apps.</string>
    <key>CFBundleName</key>
    <string>VoiceType</string>
    <key>CFBundleIdentifier</key>
    <string>com.voicetype.app</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
</dict>
</plist>
```

**Step 5: Resolve dependencies and build**

```bash
cd VoiceType
swift package resolve
swift build
```

Expected: Build succeeds. If WhisperKit causes issues with SPM executable target, switch to Xcode project approach.

**Step 6: Commit**

```bash
git add VoiceType/
git commit -m "feat: scaffold VoiceType project with SPM dependencies"
```

---

## Task 2: Design System — Colors, Fonts, Spacing

**Files:**
- Create: `Sources/VoiceType/UI/DesignSystem.swift`

**Step 1: Write the design system test**

```swift
// Tests/VoiceTypeTests/DesignSystemTests.swift
import XCTest
@testable import VoiceType

final class DesignSystemTests: XCTestCase {
    func testColorsDefined() {
        // Verify all design tokens exist and have correct values
        XCTAssertNotNil(VTColors.background)
        XCTAssertNotNil(VTColors.surface)
        XCTAssertNotNil(VTColors.textPrimary)
        XCTAssertNotNil(VTColors.textMuted)
        XCTAssertNotNil(VTColors.accent)
        XCTAssertNotNil(VTColors.recording)
        XCTAssertNotNil(VTColors.success)
    }

    func testSpacingScale() {
        XCTAssertEqual(VTSpacing.xs, 4.0)
        XCTAssertEqual(VTSpacing.sm, 8.0)
        XCTAssertEqual(VTSpacing.md, 16.0)
        XCTAssertEqual(VTSpacing.lg, 24.0)
        XCTAssertEqual(VTSpacing.xl, 32.0)
    }
}
```

**Step 2: Run test to verify it fails**

```bash
swift test --filter DesignSystemTests
```

Expected: FAIL — `VTColors` not defined.

**Step 3: Implement the design system**

```swift
// Sources/VoiceType/UI/DesignSystem.swift
import SwiftUI

// MARK: - Colors

enum VTColors {
    static let background = Color(hex: 0x1A1A1A)
    static let surface = Color(hex: 0x2A2A2A)
    static let textPrimary = Color(hex: 0xF5F5F5)
    static let textMuted = Color(hex: 0x8A8A8A)
    static let accent = Color(hex: 0x4A9EFF)
    static let recording = Color(hex: 0xFF3B30)
    static let success = Color(hex: 0x34C759)
}

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Spacing

enum VTSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

// MARK: - Typography

enum VTFont {
    static func title() -> Font { .system(size: 16, weight: .semibold, design: .default) }
    static func body() -> Font { .system(size: 13, weight: .regular, design: .default) }
    static func caption() -> Font { .system(size: 11, weight: .regular, design: .default) }
    static func mono() -> Font { .system(size: 12, weight: .regular, design: .monospaced) }
}

// MARK: - View Modifiers

struct VTCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(VTSpacing.md)
            .background(VTColors.surface)
            .cornerRadius(8)
    }
}

extension View {
    func vtCard() -> some View {
        modifier(VTCardStyle())
    }
}
```

**Step 4: Run test to verify it passes**

```bash
swift test --filter DesignSystemTests
```

Expected: PASS

**Step 5: Commit**

```bash
git add Sources/VoiceType/UI/DesignSystem.swift Tests/VoiceTypeTests/DesignSystemTests.swift
git commit -m "feat: add design system with colors, spacing, and typography"
```

---

## Task 3: App State Management

**Files:**
- Create: `Sources/VoiceType/App/AppState.swift`
- Test: `Tests/VoiceTypeTests/AppStateTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/VoiceTypeTests/AppStateTests.swift
import XCTest
@testable import VoiceType

final class AppStateTests: XCTestCase {
    func testInitialState() {
        let state = AppState()
        XCTAssertEqual(state.recordingState, .idle)
        XCTAssertTrue(state.isEnabled)
        XCTAssertNil(state.lastTranscription)
    }

    func testRecordingStateTransitions() {
        let state = AppState()
        state.recordingState = .recording
        XCTAssertEqual(state.recordingState, .recording)
        state.recordingState = .transcribing
        XCTAssertEqual(state.recordingState, .transcribing)
        state.recordingState = .done
        XCTAssertEqual(state.recordingState, .done)
    }

    func testToggleEnabled() {
        let state = AppState()
        state.isEnabled = false
        XCTAssertFalse(state.isEnabled)
    }
}
```

**Step 2: Run test to verify it fails**

```bash
swift test --filter AppStateTests
```

Expected: FAIL — `AppState` not defined.

**Step 3: Implement AppState**

```swift
// Sources/VoiceType/App/AppState.swift
import SwiftUI

enum RecordingState: Equatable {
    case idle
    case recording
    case transcribing
    case done
}

@MainActor
final class AppState: ObservableObject {
    @Published var recordingState: RecordingState = .idle
    @Published var isEnabled: Bool = true
    @Published var lastTranscription: String?
    @Published var activeAppName: String?

    /// Resets to idle after a brief delay (used after .done state)
    func resetAfterDone() {
        Task {
            try? await Task.sleep(for: .seconds(1))
            if recordingState == .done {
                recordingState = .idle
            }
        }
    }
}
```

**Step 4: Run test to verify it passes**

```bash
swift test --filter AppStateTests
```

Expected: PASS

**Step 5: Commit**

```bash
git add Sources/VoiceType/App/AppState.swift Tests/VoiceTypeTests/AppStateTests.swift
git commit -m "feat: add AppState with recording state machine"
```

---

## Task 4: Hotkey Manager — Hold-to-Talk & Toggle

**Files:**
- Create: `Sources/VoiceType/Core/HotkeyManager.swift`
- Test: `Tests/VoiceTypeTests/HotkeyManagerTests.swift`

**Step 1: Write the failing test for mode detection logic**

We can't easily test actual global hotkey registration in unit tests, but we CAN test the hold-vs-toggle detection logic in isolation.

```swift
// Tests/VoiceTypeTests/HotkeyManagerTests.swift
import XCTest
@testable import VoiceType

final class HotkeyManagerTests: XCTestCase {
    func testShortPressDetectedAsToggle() {
        let detector = PressTypeDetector(holdThreshold: 0.3)
        detector.keyDown()

        // Simulate 100ms press (short)
        let expectation = expectation(description: "short press")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let result = detector.keyUp()
            XCTAssertEqual(result, .toggle)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testLongPressDetectedAsHold() {
        let detector = PressTypeDetector(holdThreshold: 0.3)
        detector.keyDown()

        // Simulate 500ms press (long)
        let expectation = expectation(description: "long press")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let result = detector.keyUp()
            XCTAssertEqual(result, .hold)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}
```

**Step 2: Run test to verify it fails**

```bash
swift test --filter HotkeyManagerTests
```

Expected: FAIL — `PressTypeDetector` not defined.

**Step 3: Implement HotkeyManager**

```swift
// Sources/VoiceType/Core/HotkeyManager.swift
import Foundation
import HotKey
import KeyboardShortcuts
import Carbon

// MARK: - Press Type Detection

enum PressType: Equatable {
    case toggle
    case hold
}

final class PressTypeDetector {
    private var keyDownTime: Date?
    private let holdThreshold: TimeInterval

    init(holdThreshold: TimeInterval = 0.3) {
        self.holdThreshold = holdThreshold
    }

    func keyDown() {
        keyDownTime = Date()
    }

    func keyUp() -> PressType {
        guard let downTime = keyDownTime else { return .toggle }
        let duration = Date().timeIntervalSince(downTime)
        keyDownTime = nil
        return duration < holdThreshold ? .toggle : .hold
    }
}

// MARK: - Hotkey Manager

extension KeyboardShortcuts.Name {
    static let dictate = Self("dictate", default: .init(.space, modifiers: [.option]))
    static let dictateAIPolish = Self("dictateAIPolish", default: .init(.space, modifiers: [.option, .shift]))
}

@MainActor
final class HotkeyManager: ObservableObject {
    private let detector = PressTypeDetector()
    private var hotKey: HotKey?
    private var isToggleRecording = false

    var onRecordingStart: (() -> Void)?
    var onRecordingStop: (() -> Void)?
    var onToggleRecording: (() -> Void)?

    func setup() {
        // Default: Option+Space
        hotKey = HotKey(key: .space, modifiers: [.option])

        hotKey?.keyDownHandler = { [weak self] in
            guard let self else { return }
            self.detector.keyDown()
            // Start recording immediately (for hold-to-talk responsiveness)
            self.onRecordingStart?()
        }

        hotKey?.keyUpHandler = { [weak self] in
            guard let self else { return }
            let pressType = self.detector.keyUp()

            switch pressType {
            case .hold:
                // Hold released — stop recording
                self.onRecordingStop?()
            case .toggle:
                if self.isToggleRecording {
                    // Second tap — stop recording
                    self.isToggleRecording = false
                    self.onRecordingStop?()
                } else {
                    // First tap — recording already started on keyDown, just mark toggle mode
                    self.isToggleRecording = true
                }
            }
        }
    }

    func teardown() {
        hotKey = nil
    }
}
```

**Step 4: Run test to verify it passes**

```bash
swift test --filter HotkeyManagerTests
```

Expected: PASS

**Step 5: Commit**

```bash
git add Sources/VoiceType/Core/HotkeyManager.swift Tests/VoiceTypeTests/HotkeyManagerTests.swift
git commit -m "feat: add hotkey manager with hold-to-talk and toggle detection"
```

---

## Task 5: Audio Capture

**Files:**
- Create: `Sources/VoiceType/Core/AudioCapture.swift`

**Step 1: Implement AudioCapture**

Audio capture is inherently side-effectful (microphone hardware), so we test it via integration rather than unit tests. The implementation uses AVAudioEngine to capture 16kHz mono Float32 PCM — the format WhisperKit expects.

```swift
// Sources/VoiceType/Core/AudioCapture.swift
import AVFoundation

final class AudioCapture {
    private let engine = AVAudioEngine()
    private var audioBuffer: [Float] = []
    private let maxDuration: TimeInterval = 30 // 30 second max recording
    private let sampleRate: Double = 16000

    var isRecording: Bool { engine.isRunning }

    /// Request microphone permission. Returns true if granted.
    static func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// Start recording from the microphone.
    func startRecording() throws {
        audioBuffer.removeAll()

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Target format: 16kHz mono Float32 (what WhisperKit expects)
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw AudioCaptureError.formatCreationFailed
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw AudioCaptureError.converterCreationFailed
        }

        let maxSamples = Int(sampleRate * maxDuration)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            guard let self else { return }

            // Convert to 16kHz mono
            let frameCount = AVAudioFrameCount(
                Double(buffer.frameLength) * self.sampleRate / inputFormat.sampleRate
            )
            guard let convertedBuffer = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: frameCount
            ) else { return }

            var error: NSError?
            converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            if let channelData = convertedBuffer.floatChannelData?[0] {
                let samples = Array(UnsafeBufferPointer(
                    start: channelData,
                    count: Int(convertedBuffer.frameLength)
                ))
                if self.audioBuffer.count + samples.count <= maxSamples {
                    self.audioBuffer.append(contentsOf: samples)
                }
            }
        }

        engine.prepare()
        try engine.start()
    }

    /// Stop recording and return the captured audio samples.
    func stopRecording() -> [Float] {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        return audioBuffer
    }

    /// Current audio level (0.0 to 1.0) for UI visualization.
    var currentLevel: Float {
        guard isRecording else { return 0 }
        let recentSamples = audioBuffer.suffix(1600) // last 100ms at 16kHz
        let rms = sqrt(recentSamples.map { $0 * $0 }.reduce(0, +) / Float(max(recentSamples.count, 1)))
        return min(rms * 5, 1.0) // Amplify for visual range
    }
}

enum AudioCaptureError: Error, LocalizedError {
    case formatCreationFailed
    case converterCreationFailed

    var errorDescription: String? {
        switch self {
        case .formatCreationFailed: "Failed to create audio format"
        case .converterCreationFailed: "Failed to create audio converter"
        }
    }
}
```

**Step 2: Commit**

```bash
git add Sources/VoiceType/Core/AudioCapture.swift
git commit -m "feat: add CoreAudio capture with 16kHz mono conversion"
```

---

## Task 6: Transcription Engine (WhisperKit)

**Files:**
- Create: `Sources/VoiceType/Core/TranscriptionEngine.swift`
- Create: `Sources/VoiceType/Core/ModelManager.swift`

**Step 1: Implement ModelManager**

```swift
// Sources/VoiceType/Core/ModelManager.swift
import Foundation
import WhisperKit

final class ModelManager: ObservableObject {
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    @Published var isModelReady = false
    @Published var currentModelName: String = "large-v3_turbo"

    private let modelDirectory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("VoiceType/Models", isDirectory: true)
    }()

    /// Ensures the model directory exists.
    func ensureModelDirectory() throws {
        try FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
    }

    /// Returns the local path for a model if it exists.
    func localModelPath(for model: String) -> String? {
        let path = modelDirectory.appendingPathComponent(model)
        return FileManager.default.fileExists(atPath: path.path) ? path.path : nil
    }

    /// The storage directory path for WhisperKit to download models into.
    var storagePath: String {
        modelDirectory.path
    }
}
```

**Step 2: Implement TranscriptionEngine**

```swift
// Sources/VoiceType/Core/TranscriptionEngine.swift
import Foundation
import WhisperKit

@MainActor
final class TranscriptionEngine: ObservableObject {
    private var whisperKit: WhisperKit?
    private var unloadTask: Task<Void, Never>?

    @Published var isLoaded = false
    @Published var isTranscribing = false

    private let modelManager: ModelManager
    private let idleUnloadDelay: TimeInterval = 10 // Unload model after 10s idle

    init(modelManager: ModelManager) {
        self.modelManager = modelManager
    }

    /// Load the WhisperKit model. Downloads on first use.
    func loadModel() async throws {
        unloadTask?.cancel()

        if whisperKit != nil {
            isLoaded = true
            return
        }

        let config = WhisperKitConfig(
            model: modelManager.currentModelName,
            downloadBase: modelManager.storagePath,
            verbose: false,
            prewarm: true
        )

        whisperKit = try await WhisperKit(config)
        isLoaded = true
    }

    /// Transcribe audio samples (16kHz mono Float32).
    func transcribe(audioSamples: [Float]) async throws -> String {
        if !isLoaded {
            try await loadModel()
        }

        guard let whisperKit else {
            throw TranscriptionError.modelNotLoaded
        }

        isTranscribing = true
        defer {
            isTranscribing = false
            scheduleUnload()
        }

        let results = try await whisperKit.transcribe(audioArray: audioSamples)
        let text = results.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: " ")

        return text
    }

    /// Schedule model unload after idle period to free memory.
    private func scheduleUnload() {
        unloadTask?.cancel()
        unloadTask = Task {
            try? await Task.sleep(for: .seconds(idleUnloadDelay))
            if !Task.isCancelled && !isTranscribing {
                whisperKit = nil
                isLoaded = false
            }
        }
    }
}

enum TranscriptionError: Error, LocalizedError {
    case modelNotLoaded

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded: "Whisper model is not loaded"
        }
    }
}
```

**Step 3: Commit**

```bash
git add Sources/VoiceType/Core/TranscriptionEngine.swift Sources/VoiceType/Core/ModelManager.swift
git commit -m "feat: add WhisperKit transcription engine with auto-download and idle unloading"
```

---

## Task 7: Text Injector — Clipboard Paste Into Active App

**Files:**
- Create: `Sources/VoiceType/Core/TextInjector.swift`
- Test: `Tests/VoiceTypeTests/TextInjectorTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/VoiceTypeTests/TextInjectorTests.swift
import XCTest
@testable import VoiceType

final class TextInjectorTests: XCTestCase {
    func testClipboardSaveAndRestore() {
        let injector = TextInjector()

        // Set up known clipboard state
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("original", forType: .string)

        // Save clipboard
        injector.saveClipboard()

        // Modify clipboard
        pasteboard.clearContents()
        pasteboard.setString("modified", forType: .string)

        // Restore clipboard
        injector.restoreClipboard()

        XCTAssertEqual(pasteboard.string(forType: .string), "original")
    }
}
```

**Step 2: Run test to verify it fails**

```bash
swift test --filter TextInjectorTests
```

Expected: FAIL — `TextInjector` not defined.

**Step 3: Implement TextInjector**

```swift
// Sources/VoiceType/Core/TextInjector.swift
import AppKit
import CoreGraphics

final class TextInjector {
    private var savedClipboardItems: [NSPasteboardItem]?
    private let restoreDelay: UInt32 = 100_000 // 100ms in microseconds

    /// Save the current clipboard contents.
    func saveClipboard() {
        let pasteboard = NSPasteboard.general
        savedClipboardItems = pasteboard.pasteboardItems?.compactMap { item in
            let newItem = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    newItem.setData(data, forType: type)
                }
            }
            return newItem
        }
    }

    /// Restore the previously saved clipboard contents.
    func restoreClipboard() {
        guard let items = savedClipboardItems else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects(items)
        savedClipboardItems = nil
    }

    /// Inject text into the active application via clipboard + Cmd+V.
    func injectText(_ text: String) {
        saveClipboard()

        // Set text to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Small delay to let pasteboard settle
        usleep(50_000)

        // Simulate Cmd+V
        simulatePaste()

        // Restore original clipboard after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.restoreClipboard()
        }
    }

    /// Simulate Cmd+V keystroke via CGEvent.
    private func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Virtual key code 9 = "V"
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)
    }
}
```

**Step 4: Run test to verify it passes**

```bash
swift test --filter TextInjectorTests
```

Expected: PASS

**Step 5: Commit**

```bash
git add Sources/VoiceType/Core/TextInjector.swift Tests/VoiceTypeTests/TextInjectorTests.swift
git commit -m "feat: add text injector with clipboard save/restore and Cmd+V simulation"
```

---

## Task 8: Active App Detection

**Files:**
- Create: `Sources/VoiceType/Core/ActiveAppDetector.swift`

**Step 1: Implement ActiveAppDetector**

```swift
// Sources/VoiceType/Core/ActiveAppDetector.swift
import AppKit

final class ActiveAppDetector {
    /// Returns the name of the currently active (frontmost) application.
    static func currentAppName() -> String {
        NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
    }

    /// Returns the bundle identifier of the currently active application.
    static func currentAppBundleID() -> String {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "unknown"
    }

    /// Returns true if the active app is a code editor.
    static func isCodeEditor() -> Bool {
        let codeEditorBundleIDs = [
            "com.microsoft.VSCode",
            "com.todesktop.230313mzl4w4u92",  // Cursor
            "com.apple.dt.Xcode",
            "com.sublimetext.4",
            "co.gitbutler.app",
            "com.jetbrains.intellij",
        ]
        return codeEditorBundleIDs.contains(currentAppBundleID())
    }
}
```

**Step 2: Commit**

```bash
git add Sources/VoiceType/Core/ActiveAppDetector.swift
git commit -m "feat: add active app detection for context-aware behavior"
```

---

## Task 9: History Store (SQLite)

**Files:**
- Create: `Sources/VoiceType/Features/History/HistoryStore.swift`
- Create: `Sources/VoiceType/Features/History/TranscriptionRecord.swift`
- Test: `Tests/VoiceTypeTests/HistoryStoreTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/VoiceTypeTests/HistoryStoreTests.swift
import XCTest
@testable import VoiceType

final class HistoryStoreTests: XCTestCase {
    var store: HistoryStore!

    override func setUp() {
        super.setUp()
        // Use in-memory database for tests
        store = HistoryStore(path: ":memory:")
    }

    func testInsertAndFetch() throws {
        try store.insert(text: "Hello world", appName: "Gmail", appBundleID: "com.google.Chrome")
        let records = try store.fetchRecent(limit: 10)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].text, "Hello world")
        XCTAssertEqual(records[0].appName, "Gmail")
    }

    func testFetchRespectsLimit() throws {
        for i in 0..<20 {
            try store.insert(text: "Entry \(i)", appName: "App", appBundleID: "com.test")
        }
        let records = try store.fetchRecent(limit: 10)
        XCTAssertEqual(records.count, 10)
    }

    func testFetchOrderedByRecent() throws {
        try store.insert(text: "First", appName: "App", appBundleID: "com.test")
        try store.insert(text: "Second", appName: "App", appBundleID: "com.test")
        let records = try store.fetchRecent(limit: 10)
        XCTAssertEqual(records[0].text, "Second") // Most recent first
    }

    func testDeleteOldRecords() throws {
        for i in 0..<15 {
            try store.insert(text: "Entry \(i)", appName: "App", appBundleID: "com.test")
        }
        try store.pruneKeeping(count: 10)
        let records = try store.fetchRecent(limit: 20)
        XCTAssertEqual(records.count, 10)
    }

    func testWordCount() throws {
        try store.insert(text: "Hello beautiful world", appName: "App", appBundleID: "com.test")
        try store.insert(text: "One two", appName: "App", appBundleID: "com.test")
        let totalWords = try store.totalWordCount()
        XCTAssertEqual(totalWords, 5)
    }
}
```

**Step 2: Run test to verify it fails**

```bash
swift test --filter HistoryStoreTests
```

Expected: FAIL — `HistoryStore` not defined.

**Step 3: Implement TranscriptionRecord**

```swift
// Sources/VoiceType/Features/History/TranscriptionRecord.swift
import Foundation

struct TranscriptionRecord: Identifiable, Equatable {
    let id: Int64
    let text: String
    let appName: String
    let appBundleID: String
    let createdAt: Date
    let wordCount: Int

    var preview: String {
        let maxLength = 80
        if text.count <= maxLength { return text }
        return String(text.prefix(maxLength)) + "..."
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}
```

**Step 4: Implement HistoryStore**

```swift
// Sources/VoiceType/Features/History/HistoryStore.swift
import Foundation
import SQLite3

final class HistoryStore {
    private var db: OpaquePointer?

    init(path: String = HistoryStore.defaultPath) {
        guard sqlite3_open(path, &db) == SQLITE_OK else {
            fatalError("Failed to open database at \(path)")
        }
        createTable()
    }

    deinit {
        sqlite3_close(db)
    }

    static var defaultPath: String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("VoiceType", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("history.sqlite").path
    }

    private func createTable() {
        let sql = """
            CREATE TABLE IF NOT EXISTS transcriptions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                text TEXT NOT NULL,
                app_name TEXT NOT NULL,
                app_bundle_id TEXT NOT NULL,
                word_count INTEGER NOT NULL,
                created_at REAL NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_created_at ON transcriptions(created_at DESC);
        """
        sqlite3_exec(db, sql, nil, nil, nil)
    }

    func insert(text: String, appName: String, appBundleID: String) throws {
        let sql = "INSERT INTO transcriptions (text, app_name, app_bundle_id, word_count, created_at) VALUES (?, ?, ?, ?, ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw HistoryError.prepareFailed
        }
        defer { sqlite3_finalize(stmt) }

        let wordCount = text.split(separator: " ").count
        sqlite3_bind_text(stmt, 1, (text as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (appName as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (appBundleID as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 4, Int32(wordCount))
        sqlite3_bind_double(stmt, 5, Date().timeIntervalSince1970)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw HistoryError.insertFailed
        }
    }

    func fetchRecent(limit: Int) throws -> [TranscriptionRecord] {
        let sql = "SELECT id, text, app_name, app_bundle_id, word_count, created_at FROM transcriptions ORDER BY created_at DESC LIMIT ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw HistoryError.prepareFailed
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_int(stmt, 1, Int32(limit))

        var records: [TranscriptionRecord] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let record = TranscriptionRecord(
                id: sqlite3_column_int64(stmt, 0),
                text: String(cString: sqlite3_column_text(stmt, 1)),
                appName: String(cString: sqlite3_column_text(stmt, 2)),
                appBundleID: String(cString: sqlite3_column_text(stmt, 3)),
                wordCount: Int(sqlite3_column_int(stmt, 4)),
                createdAt: Date(timeIntervalSince1970: sqlite3_column_double(stmt, 5))
            )
            records.append(record)
        }
        return records
    }

    func pruneKeeping(count: Int) throws {
        let sql = "DELETE FROM transcriptions WHERE id NOT IN (SELECT id FROM transcriptions ORDER BY created_at DESC LIMIT ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw HistoryError.prepareFailed
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_int(stmt, 1, Int32(count))
        sqlite3_step(stmt)
    }

    func totalWordCount() throws -> Int {
        let sql = "SELECT COALESCE(SUM(word_count), 0) FROM transcriptions"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw HistoryError.prepareFailed
        }
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_step(stmt) == SQLITE_ROW else {
            return 0
        }
        return Int(sqlite3_column_int(stmt, 0))
    }

    func totalDictationCount() throws -> Int {
        let sql = "SELECT COUNT(*) FROM transcriptions"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw HistoryError.prepareFailed
        }
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_step(stmt) == SQLITE_ROW else {
            return 0
        }
        return Int(sqlite3_column_int(stmt, 0))
    }
}

enum HistoryError: Error {
    case prepareFailed
    case insertFailed
}
```

**Step 5: Run tests to verify they pass**

```bash
swift test --filter HistoryStoreTests
```

Expected: PASS

**Step 6: Commit**

```bash
git add Sources/VoiceType/Features/History/ Tests/VoiceTypeTests/HistoryStoreTests.swift
git commit -m "feat: add SQLite history store with insert, fetch, prune, and stats"
```

---

## Task 10: Stats Tracker — Time Saved Calculations

**Files:**
- Create: `Sources/VoiceType/Features/Stats/StatsTracker.swift`
- Test: `Tests/VoiceTypeTests/StatsTrackerTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/VoiceTypeTests/StatsTrackerTests.swift
import XCTest
@testable import VoiceType

final class StatsTrackerTests: XCTestCase {
    func testTimeSavedCalculation() {
        // Average typing speed: 40 WPM
        // Average speaking speed: 150 WPM
        // 1000 words at 40 WPM = 25 min typing
        // 1000 words at 150 WPM = 6.67 min speaking
        // Time saved = 25 - 6.67 = 18.33 min
        let saved = StatsTracker.timeSaved(wordCount: 1000)
        XCTAssertEqual(saved, 18.33, accuracy: 0.1)
    }

    func testFormattedTimeSaved() {
        // 90 minutes saved
        let formatted = StatsTracker.formatTimeSaved(minutes: 90)
        XCTAssertEqual(formatted, "1h 30m")
    }

    func testFormattedTimeSavedHoursOnly() {
        let formatted = StatsTracker.formatTimeSaved(minutes: 120)
        XCTAssertEqual(formatted, "2h 0m")
    }

    func testFormattedTimeSavedMinutesOnly() {
        let formatted = StatsTracker.formatTimeSaved(minutes: 45)
        XCTAssertEqual(formatted, "45m")
    }

    func testMilestoneDetection() {
        XCTAssertEqual(StatsTracker.milestone(forDictationCount: 1), .firstDictation)
        XCTAssertEqual(StatsTracker.milestone(forDictationCount: 100), .hundredDictations)
        XCTAssertEqual(StatsTracker.milestone(forDictationCount: 1000), .thousandDictations)
        XCTAssertNil(StatsTracker.milestone(forDictationCount: 50))
    }
}
```

**Step 2: Run test to verify it fails**

```bash
swift test --filter StatsTrackerTests
```

Expected: FAIL — `StatsTracker` not defined.

**Step 3: Implement StatsTracker**

```swift
// Sources/VoiceType/Features/Stats/StatsTracker.swift
import Foundation
import UserNotifications

enum Milestone: Equatable {
    case firstDictation
    case hundredDictations
    case thousandDictations
    case hourSaved

    var message: String {
        switch self {
        case .firstDictation: "Your first dictation! Welcome to VoiceType."
        case .hundredDictations: "You've dictated 100 times. You're a natural."
        case .thousandDictations: "1,000 dictations. You're basically a podcaster now."
        case .hourSaved: "VoiceType just saved you an hour. Not bad."
        }
    }
}

enum StatsTracker {
    private static let typingWPM: Double = 40
    private static let speakingWPM: Double = 150

    /// Calculate minutes saved by dictating instead of typing.
    static func timeSaved(wordCount: Int) -> Double {
        let typingMinutes = Double(wordCount) / typingWPM
        let speakingMinutes = Double(wordCount) / speakingWPM
        return typingMinutes - speakingMinutes
    }

    /// Format minutes into a human-readable string.
    static func formatTimeSaved(minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }

    /// Check if a dictation count triggers a milestone.
    static func milestone(forDictationCount count: Int) -> Milestone? {
        switch count {
        case 1: .firstDictation
        case 100: .hundredDictations
        case 1000: .thousandDictations
        default: nil
        }
    }

    /// Check if total time saved crossed the 1-hour threshold.
    static func checkTimeMilestone(previousWordCount: Int, newWordCount: Int) -> Milestone? {
        let previousMinutes = timeSaved(wordCount: previousWordCount)
        let newMinutes = timeSaved(wordCount: newWordCount)
        if previousMinutes < 60 && newMinutes >= 60 {
            return .hourSaved
        }
        return nil
    }

    /// Show a native macOS notification for a milestone.
    static func showMilestoneNotification(_ milestone: Milestone) {
        let content = UNMutableNotificationContent()
        content.title = "VoiceType"
        content.body = milestone.message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "milestone-\(String(describing: milestone))",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
```

**Step 4: Run tests to verify they pass**

```bash
swift test --filter StatsTrackerTests
```

Expected: PASS

**Step 5: Commit**

```bash
git add Sources/VoiceType/Features/Stats/StatsTracker.swift Tests/VoiceTypeTests/StatsTrackerTests.swift
git commit -m "feat: add stats tracker with time saved calculations and milestones"
```

---

## Task 11: Wire the Core Pipeline

**Files:**
- Create: `Sources/VoiceType/Core/DictationPipeline.swift`

This is the central coordinator that wires hotkey → audio → transcription → text injection → history.

**Step 1: Implement DictationPipeline**

```swift
// Sources/VoiceType/Core/DictationPipeline.swift
import Foundation

@MainActor
final class DictationPipeline: ObservableObject {
    let appState: AppState
    let hotkeyManager: HotkeyManager
    let audioCapture: AudioCapture
    let transcriptionEngine: TranscriptionEngine
    let textInjector: TextInjector
    let historyStore: HistoryStore
    let modelManager: ModelManager

    init() {
        self.appState = AppState()
        self.hotkeyManager = HotkeyManager()
        self.audioCapture = AudioCapture()
        self.modelManager = ModelManager()
        self.transcriptionEngine = TranscriptionEngine(modelManager: modelManager)
        self.textInjector = TextInjector()
        self.historyStore = HistoryStore()

        setupHotkeyCallbacks()
    }

    private func setupHotkeyCallbacks() {
        hotkeyManager.onRecordingStart = { [weak self] in
            Task { @MainActor in
                self?.startRecording()
            }
        }

        hotkeyManager.onRecordingStop = { [weak self] in
            Task { @MainActor in
                await self?.stopRecordingAndTranscribe()
            }
        }
    }

    func setup() {
        hotkeyManager.setup()
    }

    private func startRecording() {
        guard appState.isEnabled, appState.recordingState == .idle else { return }

        // Capture active app BEFORE recording starts
        appState.activeAppName = ActiveAppDetector.currentAppName()

        do {
            try audioCapture.startRecording()
            appState.recordingState = .recording
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    private func stopRecordingAndTranscribe() async {
        guard appState.recordingState == .recording else { return }

        let samples = audioCapture.stopRecording()
        appState.recordingState = .transcribing

        // Skip if too short (< 0.5 seconds of audio)
        guard samples.count > 8000 else {
            appState.recordingState = .idle
            return
        }

        do {
            let text = try await transcriptionEngine.transcribe(audioSamples: samples)

            guard !text.isEmpty else {
                appState.recordingState = .idle
                return
            }

            // Track stats before injection
            let previousWordCount = (try? historyStore.totalWordCount()) ?? 0
            let previousDictationCount = (try? historyStore.totalDictationCount()) ?? 0

            // Inject text into active app
            textInjector.injectText(text)

            // Save to history
            let appName = appState.activeAppName ?? "Unknown"
            let bundleID = ActiveAppDetector.currentAppBundleID()
            try? historyStore.insert(text: text, appName: appName, appBundleID: bundleID)

            // Update state
            appState.lastTranscription = text
            appState.recordingState = .done
            appState.resetAfterDone()

            // Check milestones
            let newWordCount = (try? historyStore.totalWordCount()) ?? 0
            let newDictationCount = (try? historyStore.totalDictationCount()) ?? 0

            if let milestone = StatsTracker.milestone(forDictationCount: newDictationCount) {
                StatsTracker.showMilestoneNotification(milestone)
            }
            if let milestone = StatsTracker.checkTimeMilestone(previousWordCount: previousWordCount, newWordCount: newWordCount) {
                StatsTracker.showMilestoneNotification(milestone)
            }

            // Prune history (free tier: 10 entries)
            try? historyStore.pruneKeeping(count: 10)

        } catch {
            print("Transcription failed: \(error)")
            appState.recordingState = .idle
        }
    }
}
```

**Step 2: Commit**

```bash
git add Sources/VoiceType/Core/DictationPipeline.swift
git commit -m "feat: wire core dictation pipeline — hotkey to audio to transcription to paste"
```

---

## Task 12: Menu Bar UI

**Files:**
- Create: `Sources/VoiceType/UI/MenuBarView.swift`
- Create: `Sources/VoiceType/UI/RecordingIndicator.swift`
- Modify: `Sources/VoiceType/App/VoiceTypeApp.swift`

**Step 1: Implement RecordingIndicator**

```swift
// Sources/VoiceType/UI/RecordingIndicator.swift
import SwiftUI

struct RecordingIndicator: View {
    let state: RecordingState

    var body: some View {
        Image(systemName: iconName)
            .symbolRenderingMode(.palette)
            .foregroundStyle(iconColor)
            .font(.system(size: 14, weight: .medium))
            .animation(.easeInOut(duration: 0.2), value: state)
    }

    private var iconName: String {
        switch state {
        case .idle: "mic.fill"
        case .recording: "mic.fill"
        case .transcribing: "ellipsis"
        case .done: "checkmark"
        }
    }

    private var iconColor: Color {
        switch state {
        case .idle: .primary
        case .recording: VTColors.recording
        case .transcribing: VTColors.accent
        case .done: VTColors.success
        }
    }
}
```

**Step 2: Implement MenuBarView**

```swift
// Sources/VoiceType/UI/MenuBarView.swift
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var pipeline: DictationPipeline

    @State private var recentRecords: [TranscriptionRecord] = []
    @State private var timeSavedText: String = "0m"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            header
            Divider()

            // Stats
            statsRow
            Divider()

            // Recent transcriptions
            recentSection

            if !recentRecords.isEmpty {
                Divider()
            }

            // Hotkey hints
            hotkeyHints
            Divider()

            // Footer
            footer
        }
        .frame(width: 320)
        .onAppear { refreshData() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("VoiceType")
                .font(VTFont.title())
            Spacer()
            Toggle("", isOn: $pipeline.appState.isEnabled)
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.horizontal, VTSpacing.md)
        .padding(.vertical, VTSpacing.sm)
    }

    // MARK: - Stats

    private var statsRow: some View {
        Text("You've saved \(timeSavedText) typing this month.")
            .font(VTFont.caption())
            .foregroundStyle(VTColors.textMuted)
            .padding(.horizontal, VTSpacing.md)
            .padding(.vertical, VTSpacing.sm)
    }

    // MARK: - Recent

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if recentRecords.isEmpty {
                Text("No dictations yet. Press ⌥Space to start.")
                    .font(VTFont.caption())
                    .foregroundStyle(VTColors.textMuted)
                    .padding(VTSpacing.md)
            } else {
                Text("Recent")
                    .font(VTFont.caption())
                    .foregroundStyle(VTColors.textMuted)
                    .padding(.horizontal, VTSpacing.md)
                    .padding(.top, VTSpacing.sm)

                ForEach(recentRecords.prefix(5)) { record in
                    recentRow(record)
                }
            }
        }
    }

    private func recentRow(_ record: TranscriptionRecord) -> some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(record.text, forType: .string)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.preview)
                    .font(VTFont.body())
                    .lineLimit(2)
                HStack {
                    Text(record.appName)
                    Text("·")
                    Text(record.relativeTime)
                }
                .font(VTFont.caption())
                .foregroundStyle(VTColors.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, VTSpacing.md)
        .padding(.vertical, VTSpacing.xs)
    }

    // MARK: - Hotkey Hints

    private var hotkeyHints: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("⌥Space")
                    .font(VTFont.mono())
                Spacer()
                Text("Hold or toggle")
                    .font(VTFont.caption())
                    .foregroundStyle(VTColors.textMuted)
            }
        }
        .padding(.horizontal, VTSpacing.md)
        .padding(.vertical, VTSpacing.sm)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Button("Settings...") {
                // TODO: Open settings window
            }
            .keyboardShortcut(",", modifiers: .command)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, VTSpacing.md)
            .padding(.vertical, VTSpacing.xs)

            Button("Quit VoiceType") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, VTSpacing.md)
            .padding(.vertical, VTSpacing.xs)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data

    private func refreshData() {
        recentRecords = (try? pipeline.historyStore.fetchRecent(limit: 5)) ?? []
        let totalWords = (try? pipeline.historyStore.totalWordCount()) ?? 0
        let minutes = StatsTracker.timeSaved(wordCount: totalWords)
        timeSavedText = StatsTracker.formatTimeSaved(minutes: minutes)
    }
}
```

**Step 3: Update VoiceTypeApp.swift**

```swift
// Sources/VoiceType/App/VoiceTypeApp.swift
import SwiftUI

@main
struct VoiceTypeApp: App {
    @StateObject private var pipeline = DictationPipeline()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(pipeline: pipeline)
        } label: {
            RecordingIndicator(state: pipeline.appState.recordingState)
        }
        .menuBarExtraStyle(.window)
    }

    init() {
        // Pipeline setup happens after SwiftUI initializes
        DispatchQueue.main.async {
            // Request permissions and setup will be handled by onboarding
        }
    }
}
```

**Step 4: Commit**

```bash
git add Sources/VoiceType/UI/ Sources/VoiceType/App/VoiceTypeApp.swift
git commit -m "feat: add menu bar UI with recording indicator, history, and stats"
```

---

## Task 13: Settings View

**Files:**
- Create: `Sources/VoiceType/Features/Settings/SettingsView.swift`
- Create: `Sources/VoiceType/Features/Settings/UserSettings.swift`

**Step 1: Implement UserSettings**

```swift
// Sources/VoiceType/Features/Settings/UserSettings.swift
import Foundation
import KeyboardShortcuts

final class UserSettings: ObservableObject {
    @Published var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin") }
    }
    @Published var autoPunctuation: Bool {
        didSet { UserDefaults.standard.set(autoPunctuation, forKey: "autoPunctuation") }
    }
    @Published var language: String {
        didSet { UserDefaults.standard.set(language, forKey: "language") }
    }
    @Published var silenceTimeout: Double {
        didSet { UserDefaults.standard.set(silenceTimeout, forKey: "silenceTimeout") }
    }
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }

    init() {
        let defaults = UserDefaults.standard
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        self.autoPunctuation = defaults.object(forKey: "autoPunctuation") as? Bool ?? true
        self.language = defaults.string(forKey: "language") ?? "en"
        self.silenceTimeout = defaults.object(forKey: "silenceTimeout") as? Double ?? 2.0
        self.soundEnabled = defaults.object(forKey: "soundEnabled") as? Bool ?? true
    }
}
```

**Step 2: Implement SettingsView**

```swift
// Sources/VoiceType/Features/Settings/SettingsView.swift
import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @ObservedObject var settings: UserSettings
    @ObservedObject var modelManager: ModelManager

    var body: some View {
        Form {
            // General
            Section("General") {
                KeyboardShortcuts.Recorder("Dictation hotkey:", name: .dictate)
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                Toggle("Sound effects", isOn: $settings.soundEnabled)
            }

            // Transcription
            Section("Transcription") {
                Picker("Language", selection: $settings.language) {
                    Text("English").tag("en")
                    Text("Spanish").tag("es")
                    Text("French").tag("fr")
                    Text("German").tag("de")
                    Text("Japanese").tag("ja")
                    Text("Chinese").tag("zh")
                }

                Picker("Model", selection: $modelManager.currentModelName) {
                    Text("Large v3 Turbo (recommended)").tag("large-v3_turbo")
                    Text("Large v3 Turbo (compressed, 632MB)").tag("openai_whisper-large-v3-v20240930_turbo_632MB")
                    Text("Base (fast, less accurate)").tag("base")
                }

                Toggle("Auto-punctuation", isOn: $settings.autoPunctuation)

                HStack {
                    Text("Silence timeout")
                    Slider(value: $settings.silenceTimeout, in: 1...5, step: 0.5)
                    Text("\(settings.silenceTimeout, specifier: "%.1f")s")
                        .font(VTFont.mono())
                        .frame(width: 30)
                }
            }

            // About
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("0.1.0")
                        .foregroundStyle(VTColors.textMuted)
                }

                Link("GitHub", destination: URL(string: "https://github.com/voicetype/voicetype")!)

                HStack {
                    Text("License")
                    Spacer()
                    Text("Free")
                        .foregroundStyle(VTColors.textMuted)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 420)
    }
}
```

**Step 3: Commit**

```bash
git add Sources/VoiceType/Features/Settings/
git commit -m "feat: add settings view with hotkey recorder, language, and model selection"
```

---

## Task 14: Onboarding Flow

**Files:**
- Create: `Sources/VoiceType/Features/Onboarding/OnboardingView.swift`

**Step 1: Implement OnboardingView**

```swift
// Sources/VoiceType/Features/Onboarding/OnboardingView.swift
import SwiftUI
import AVFoundation

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var micPermissionGranted = false
    @State private var accessibilityGranted = false

    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: VTSpacing.xl) {
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                permissionsPage.tag(1)
                readyPage.tag(2)
            }
            .tabViewStyle(.automatic)
        }
        .frame(width: 400, height: 320)
        .background(.ultraThinMaterial)
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: VTSpacing.lg) {
            Spacer()
            Image(systemName: "mic.fill")
                .font(.system(size: 48))
                .foregroundStyle(VTColors.accent)
            Text("Welcome to VoiceType")
                .font(.system(size: 22, weight: .semibold))
            Text("Dictate anywhere on your Mac.")
                .font(VTFont.body())
                .foregroundStyle(VTColors.textMuted)
            Spacer()
            Button("Continue") { currentPage = 1 }
                .buttonStyle(.borderedProminent)
        }
        .padding(VTSpacing.xl)
    }

    // MARK: - Page 2: Permissions

    private var permissionsPage: some View {
        VStack(spacing: VTSpacing.lg) {
            Spacer()

            VStack(spacing: VTSpacing.md) {
                permissionRow(
                    icon: "mic.fill",
                    title: "Microphone",
                    description: "To hear your voice",
                    granted: micPermissionGranted
                ) {
                    Task {
                        micPermissionGranted = await AudioCapture.requestPermission()
                    }
                }

                permissionRow(
                    icon: "hand.raised.fill",
                    title: "Accessibility",
                    description: "To type text into your apps",
                    granted: accessibilityGranted
                ) {
                    requestAccessibility()
                }
            }

            Spacer()

            Button("Continue") { currentPage = 2 }
                .buttonStyle(.borderedProminent)
                .disabled(!micPermissionGranted)
        }
        .padding(VTSpacing.xl)
    }

    private func permissionRow(icon: String, title: String, description: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: VTSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(granted ? VTColors.success : VTColors.accent)
                .frame(width: 32)

            VStack(alignment: .leading) {
                Text(title).font(VTFont.body())
                Text(description).font(VTFont.caption()).foregroundStyle(VTColors.textMuted)
            }

            Spacer()

            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(VTColors.success)
            } else {
                Button("Grant") { action() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(VTSpacing.sm)
    }

    private func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        accessibilityGranted = AXIsProcessTrustedWithOptions(options)
    }

    // MARK: - Page 3: Ready

    private var readyPage: some View {
        VStack(spacing: VTSpacing.lg) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(VTColors.success)
            Text("Ready to go")
                .font(.system(size: 22, weight: .semibold))
            VStack(spacing: VTSpacing.xs) {
                Text("Your hotkey: ⌥Space")
                    .font(VTFont.body())
                Text("Hold to talk, or tap to toggle.")
                    .font(VTFont.caption())
                    .foregroundStyle(VTColors.textMuted)
            }
            Spacer()
            Button("Start Using VoiceType") {
                UserDefaults.standard.set(true, forKey: "onboardingComplete")
                onComplete()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(VTSpacing.xl)
    }
}
```

**Step 2: Commit**

```bash
git add Sources/VoiceType/Features/Onboarding/
git commit -m "feat: add 3-screen onboarding flow with permission requests"
```

---

## Task 15: Share Card for Stats

**Files:**
- Create: `Sources/VoiceType/Features/Stats/ShareCardView.swift`

**Step 1: Implement ShareCardView**

```swift
// Sources/VoiceType/Features/Stats/ShareCardView.swift
import SwiftUI

struct ShareCardView: View {
    let wordCount: Int
    let timeSaved: String
    let dictationCount: Int

    var body: some View {
        VStack(spacing: VTSpacing.lg) {
            Image(systemName: "mic.fill")
                .font(.system(size: 28))
                .foregroundStyle(VTColors.accent)

            Text("VoiceType")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(VTColors.textPrimary)

            VStack(spacing: VTSpacing.xs) {
                Text("I dictated \(wordCount.formatted()) words and saved")
                Text("\(timeSaved) of typing this month.")
            }
            .font(VTFont.body())
            .foregroundStyle(VTColors.textPrimary)
            .multilineTextAlignment(.center)

            Text("voicetype.app")
                .font(VTFont.caption())
                .foregroundStyle(VTColors.textMuted)
        }
        .padding(VTSpacing.xl)
        .frame(width: 340, height: 220)
        .background(VTColors.background)
        .cornerRadius(16)
    }

    /// Render the view as an NSImage for sharing.
    @MainActor
    func renderAsImage() -> NSImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = 2.0 // Retina
        return renderer.nsImage
    }
}
```

**Step 2: Commit**

```bash
git add Sources/VoiceType/Features/Stats/ShareCardView.swift
git commit -m "feat: add shareable stats card with image rendering"
```

---

## Task 16: Integrate Settings Window into App

**Files:**
- Modify: `Sources/VoiceType/App/VoiceTypeApp.swift`

**Step 1: Update app to include settings, onboarding, and full pipeline startup**

```swift
// Sources/VoiceType/App/VoiceTypeApp.swift
import SwiftUI
import Sparkle

@main
struct VoiceTypeApp: App {
    @StateObject private var pipeline = DictationPipeline()
    @StateObject private var settings = UserSettings()
    @StateObject private var updaterVM = UpdaterViewModel()

    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboardingComplete")

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(pipeline: pipeline)
        } label: {
            RecordingIndicator(state: pipeline.appState.recordingState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(settings: settings, modelManager: pipeline.modelManager)
        }

        // Onboarding window
        if showOnboarding {
            Window("Welcome to VoiceType", id: "onboarding") {
                OnboardingView {
                    showOnboarding = false
                    pipeline.setup()
                }
            }
            .windowStyle(.hiddenTitleBar)
            .windowResizability(.contentSize)
            .defaultPosition(.center)
        }
    }
}

// MARK: - Sparkle Updater

final class UpdaterViewModel: ObservableObject {
    private let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}
```

**Step 2: Commit**

```bash
git add Sources/VoiceType/App/VoiceTypeApp.swift
git commit -m "feat: integrate settings window, onboarding, and Sparkle updater into app"
```

---

## Task 17: History View for Menu Bar

**Files:**
- Create: `Sources/VoiceType/Features/History/HistoryView.swift`

**Step 1: Implement HistoryView**

```swift
// Sources/VoiceType/Features/History/HistoryView.swift
import SwiftUI

struct HistoryView: View {
    let records: [TranscriptionRecord]
    var onCopy: ((TranscriptionRecord) -> Void)?

    var body: some View {
        if records.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text("Recent")
                    .font(VTFont.caption())
                    .foregroundStyle(VTColors.textMuted)
                    .padding(.horizontal, VTSpacing.md)
                    .padding(.top, VTSpacing.sm)
                    .padding(.bottom, VTSpacing.xs)

                ForEach(records.prefix(5)) { record in
                    HistoryRow(record: record) {
                        onCopy?(record)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        Text("No dictations yet. Press ⌥Space to start.")
            .font(VTFont.caption())
            .foregroundStyle(VTColors.textMuted)
            .padding(VTSpacing.md)
    }
}

struct HistoryRow: View {
    let record: TranscriptionRecord
    let onCopy: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onCopy) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.preview)
                        .font(VTFont.body())
                        .lineLimit(2)
                    HStack(spacing: 4) {
                        Text(record.appName)
                        Text("·")
                        Text(record.relativeTime)
                    }
                    .font(VTFont.caption())
                    .foregroundStyle(VTColors.textMuted)
                }

                Spacer()

                if isHovering {
                    Image(systemName: "doc.on.doc")
                        .font(VTFont.caption())
                        .foregroundStyle(VTColors.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.horizontal, VTSpacing.md)
            .padding(.vertical, VTSpacing.xs)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
```

**Step 2: Commit**

```bash
git add Sources/VoiceType/Features/History/HistoryView.swift
git commit -m "feat: add history list view with hover-to-reveal copy button"
```

---

## Task 18: Build, Test, and Fix

**Step 1: Run full test suite**

```bash
cd VoiceType
swift test
```

Fix any compilation errors or test failures.

**Step 2: Build the app**

```bash
swift build -c release
```

**Step 3: Test manually**

Run the built binary and verify:
- Menu bar icon appears
- Onboarding shows on first launch
- Hotkey registers (⌥Space)
- Microphone captures audio
- Transcription works (model downloads on first use)
- Text pastes into active app
- History populates in dropdown

**Step 4: Commit any fixes**

```bash
git add -A
git commit -m "fix: resolve build issues and integration bugs"
```

---

## Task 19: README and Distribution

**Files:**
- Create: `README.md`
- Create: `LICENSE`
- Create: `Makefile`

**Step 1: Create LICENSE (MIT)**

```
MIT License

Copyright (c) 2026 VoiceType

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

**Step 2: Create Makefile**

```makefile
.PHONY: build test clean release dmg

build:
	swift build

test:
	swift test

clean:
	swift package clean

release:
	swift build -c release

dmg: release
	@echo "Creating DMG..."
	@mkdir -p dist
	@hdiutil create -volname "VoiceType" -srcfolder .build/release/VoiceType -ov -format UDZO dist/VoiceType.dmg
	@echo "DMG created at dist/VoiceType.dmg"
```

**Step 3: Create README.md**

A concise README with:
- One-line description
- Screenshot/GIF placeholder
- Installation instructions (brew + manual .dmg)
- Usage (hotkey, hold-to-talk, toggle)
- Building from source
- Contributing
- License

**Step 4: Commit**

```bash
git add README.md LICENSE Makefile
git commit -m "docs: add README, LICENSE (MIT), and Makefile for build/distribution"
```

---

## Task 20: Final Integration Test & Polish

**Step 1: Full end-to-end test**

1. Build release: `make release`
2. Launch the app
3. Complete onboarding
4. Hold ⌥Space, speak a sentence, release
5. Verify text appears in TextEdit / Notes
6. Check history in dropdown
7. Verify "time saved" stat updates
8. Open Settings, change hotkey, verify it works
9. Quit and relaunch — verify settings persist

**Step 2: Fix any remaining issues**

**Step 3: Final commit**

```bash
git add -A
git commit -m "chore: final polish and integration test fixes"
```

---

## Summary

| Task | Description | Estimated Complexity |
|------|-------------|---------------------|
| 1 | Project scaffold + SPM dependencies | Medium |
| 2 | Design system (colors, fonts, spacing) | Simple |
| 3 | AppState management | Simple |
| 4 | Hotkey manager (hold + toggle) | Medium |
| 5 | Audio capture (CoreAudio 16kHz) | Medium |
| 6 | Transcription engine (WhisperKit) | Medium |
| 7 | Text injector (clipboard + Cmd+V) | Medium |
| 8 | Active app detection | Simple |
| 9 | History store (SQLite) | Medium |
| 10 | Stats tracker (time saved, milestones) | Simple |
| 11 | Core pipeline (wire everything together) | Medium |
| 12 | Menu bar UI | Medium |
| 13 | Settings view | Medium |
| 14 | Onboarding flow | Medium |
| 15 | Share card | Simple |
| 16 | App integration (settings + onboarding) | Medium |
| 17 | History view component | Simple |
| 18 | Build, test, fix | Medium |
| 19 | README + LICENSE + Makefile | Simple |
| 20 | Final integration test | Medium |

**Total: 20 tasks.** Core functionality (Tasks 1-11) gets you a working dictation tool. UI polish (Tasks 12-17) makes it shippable. Distribution (Tasks 18-20) makes it shareable.
