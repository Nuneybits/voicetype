import SwiftUI
import AppKit

struct NotepadView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var modelManager: ModelManager
    let onToggleRecording: () -> Void
    let onCopyAll: () -> Void
    let onClear: () -> Void
    let onClose: () -> Void
    @ObservedObject var settings: UserSettings

    @State private var copiedBlockID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            header
            StateStrip(state: appState.recordingState)
            waveformArea
            Divider().background(VTColors.border)
            textArea
            Divider().background(VTColors.border)
            bottomBar
        }
        .frame(width: 380, height: 480)
        .background(VTColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.5), radius: 20, y: 8)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("VoiceType")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(VTColors.textPrimary)
                .tracking(1.2)

            Spacer()

            if !appState.transcriptionBlocks.isEmpty {
                Text("\(appState.transcriptionBlocks.count) \(appState.transcriptionBlocks.count == 1 ? "note" : "notes")")
                    .font(VTFont.caption())
                    .foregroundStyle(VTColors.textMuted)
            }

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(VTColors.textMuted)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, VTSpacing.md)
        .padding(.vertical, 12)
        .background(VTColors.surface)
    }

    // MARK: - Waveform Area

    private var waveformArea: some View {
        ZStack {
            // State-specific background tints
            if appState.recordingState == .recording {
                VTColors.recording.opacity(0.05)
            } else if appState.recordingState == .transcribing {
                VTColors.accent.opacity(0.05)
            } else {
                VTColors.surface.opacity(0.5)
            }

            if appState.recordingState == .recording {
                VStack(spacing: 4) {
                    WaveformView(levels: appState.audioLevelHistory)
                    HStack {
                        Circle()
                            .fill(VTColors.recording)
                            .frame(width: 6, height: 6)
                            .modifier(PulsingDot())

                        Text("Recording")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(VTColors.recording)

                        Spacer()

                        Text(formatDuration(appState.recordingDuration))
                            .font(VTFont.mono())
                            .foregroundStyle(VTColors.textSecondary)
                    }
                }
                .padding(.horizontal, VTSpacing.md)
                .transition(.opacity)
            } else if appState.recordingState == .transcribing {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(VTColors.accent)

                    Text(modelManager.isDownloading ? "Preparing speech model..." : "Transcribing...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(VTColors.accent)

                    Spacer()

                    Text(formatDuration(appState.transcribingElapsed))
                        .font(VTFont.mono())
                        .foregroundStyle(VTColors.textSecondary)
                }
                .padding(.horizontal, VTSpacing.md)
                .transition(.opacity)
            } else if appState.recordingState == .done {
                // Session stats shown briefly after recording
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(VTColors.success)

                    if appState.lastSessionWordCount > 0 {
                        Text("\(appState.lastSessionWordCount) words")
                            .font(VTFont.mono())
                            .foregroundStyle(VTColors.textSecondary)

                        if appState.lastSessionWPM > 0 {
                            Text("·")
                                .foregroundStyle(VTColors.textMuted)
                            Text("\(appState.lastSessionWPM) wpm")
                                .font(VTFont.mono())
                                .foregroundStyle(VTColors.textSecondary)
                        }
                    }
                }
                .transition(.opacity)
            } else {
                // Idle — clean ready state
                VStack(spacing: 6) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(VTColors.textMuted.opacity(0.3))
                    Text("Ready")
                        .font(VTFont.caption())
                        .foregroundStyle(VTColors.textMuted.opacity(0.5))
                }
            }
        }
        .frame(height: 72)
        .animation(.easeInOut(duration: 0.3), value: appState.recordingState)
    }

    // MARK: - Text Area

    private var textArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: VTSpacing.md) {
                    if appState.transcriptionBlocks.isEmpty && appState.recordingState == .idle {
                        emptyState
                    } else {
                        ForEach(Array(appState.transcriptionBlocks.enumerated()), id: \.element.id) { index, block in
                            TranscriptionBlockView(
                                block: block,
                                isCopied: copiedBlockID == block.id,
                                onCopy: {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(block.text, forType: .string)
                                    copiedBlockID = block.id
                                    // Reset after 2 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        if copiedBlockID == block.id {
                                            copiedBlockID = nil
                                        }
                                    }
                                }
                            )
                            .id(index)

                            // Divider between blocks
                            if index < appState.transcriptionBlocks.count - 1 {
                                Divider()
                                    .background(VTColors.border)
                                    .padding(.vertical, VTSpacing.xs)
                            }
                        }

                        if appState.recordingState == .recording {
                            if appState.isStreaming {
                                // Live streaming text
                                if !appState.streamingConfirmedText.isEmpty {
                                    Text(appState.streamingConfirmedText)
                                        .font(VTFont.body())
                                        .foregroundStyle(VTColors.textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .id("confirmed")
                                }
                                if !appState.streamingHypothesisText.isEmpty {
                                    Text(appState.streamingHypothesisText)
                                        .font(VTFont.body())
                                        .foregroundStyle(VTColors.textSecondary)
                                        .italic()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .id("hypothesis")
                                }
                                if appState.streamingConfirmedText.isEmpty && appState.streamingHypothesisText.isEmpty {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(VTColors.recording.opacity(0.5))
                                            .frame(width: 8, height: 8)
                                            .modifier(PulsingDot())
                                        Text("Listening...")
                                            .font(VTFont.body())
                                            .foregroundStyle(VTColors.textMuted)
                                            .italic()
                                    }
                                    .id("listening")
                                }
                            } else {
                                // Batch mode
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(VTColors.recording.opacity(0.5))
                                        .frame(width: 8, height: 8)
                                        .modifier(PulsingDot())
                                    Text("Listening...")
                                        .font(VTFont.body())
                                        .foregroundStyle(VTColors.textMuted)
                                        .italic()
                                }
                                .id("listening")
                            }
                        }

                        if appState.recordingState == .transcribing {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .controlSize(.mini)
                                    .tint(VTColors.accent)
                                Text("Processing...")
                                    .font(VTFont.body())
                                    .foregroundStyle(VTColors.textMuted)
                                    .italic()
                            }
                            .id("processing")
                        }
                    }
                }
                .padding(VTSpacing.md)
            }
            .frame(maxHeight: .infinity)
            .background(VTColors.background)
            .onChange(of: appState.transcriptionBlocks.count) { _, _ in
                withAnimation {
                    proxy.scrollTo(appState.transcriptionBlocks.count - 1, anchor: .bottom)
                }
            }
            .onChange(of: appState.streamingConfirmedText) { _, _ in
                withAnimation {
                    proxy.scrollTo("confirmed", anchor: .bottom)
                }
            }
            .onChange(of: appState.streamingHypothesisText) { _, _ in
                withAnimation {
                    proxy.scrollTo("hypothesis", anchor: .bottom)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: VTSpacing.sm) {
            Image(systemName: "mic.fill")
                .font(.system(size: 32))
                .foregroundStyle(VTColors.textMuted.opacity(0.4))
            Text("Press the record button or")
                .font(VTFont.caption())
                .foregroundStyle(VTColors.textMuted)
            HStack(spacing: 3) {
                KeyCap(label: "\u{21E7}")
                KeyCap(label: "\u{2318}")
                KeyCap(label: "Space")
            }
            Text("to start dictating")
                .font(VTFont.caption())
                .foregroundStyle(VTColors.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, VTSpacing.xl)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            if appState.totalWords > 0 {
                Text("\(appState.totalWords) words")
                    .font(VTFont.mono())
                    .foregroundStyle(VTColors.textMuted)
            } else {
                Text("0 words")
                    .font(VTFont.mono())
                    .foregroundStyle(VTColors.textMuted.opacity(0.5))
            }

            Spacer()

            RecordButton(
                isRecording: appState.recordingState == .recording,
                action: onToggleRecording
            )

            Spacer()

            HStack(spacing: VTSpacing.sm) {
                if !appState.transcriptionBlocks.isEmpty {
                    Button(action: onClear) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(VTColors.textMuted)
                    }
                    .buttonStyle(.plain)
                    .help("Clear all")
                }

                Button(action: onCopyAll) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                        Text("Copy")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(appState.transcriptionBlocks.isEmpty ? VTColors.textMuted.opacity(0.4) : VTColors.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(VTColors.surface)
                            .stroke(VTColors.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(appState.transcriptionBlocks.isEmpty)
            }
        }
        .padding(.horizontal, VTSpacing.md)
        .padding(.vertical, 10)
        .background(VTColors.surface)
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Transcription Block (click to copy)

struct TranscriptionBlockView: View {
    let block: TranscriptionBlock
    let isCopied: Bool
    let onCopy: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onCopy) {
            VStack(alignment: .leading, spacing: VTSpacing.xs) {
                // Header: timestamp + copy indicator
                HStack {
                    Text(block.timestamp, style: .time)
                        .font(VTFont.caption())
                        .foregroundStyle(VTColors.textMuted)
                    Spacer()
                    if isCopied {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                            Text("Copied")
                                .font(VTFont.caption())
                        }
                        .foregroundStyle(VTColors.success)
                        .transition(.opacity)
                    } else if isHovering {
                        HStack(spacing: 2) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 9))
                            Text("Click to copy")
                                .font(VTFont.caption())
                        }
                        .foregroundStyle(VTColors.textMuted)
                        .transition(.opacity)
                    }
                }

                // Text with left accent border
                Text(block.text)
                    .font(VTFont.body())
                    .foregroundStyle(VTColors.textPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, VTSpacing.sm)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(isCopied ? VTColors.success.opacity(0.4) : VTColors.accent.opacity(0.3))
                            .frame(width: 2)
                    }
            }
            .padding(.vertical, VTSpacing.xs)
            .padding(.horizontal, VTSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? VTColors.surfaceHover : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .animation(.easeInOut(duration: 0.2), value: isCopied)
    }
}

// MARK: - Pulsing Animation

struct PulsingDot: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.3 : 0.8)
            .opacity(isPulsing ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}
