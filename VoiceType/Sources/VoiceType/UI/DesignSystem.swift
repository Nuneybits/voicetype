import SwiftUI

// MARK: - Colors (MoMA / Dieter Rams palette)

enum VTColors {
    static let background = Color(hex: 0x141414)
    static let surface = Color(hex: 0x1E1E1E)
    static let surfaceHover = Color(hex: 0x282828)
    static let textPrimary = Color(hex: 0xFAFAFA)
    static let textSecondary = Color(hex: 0xA0A0A0)
    static let textMuted = Color(hex: 0x606060)
    static let recording = Color(hex: 0xE53935)
    static let accent = Color(hex: 0xF5A623)
    static let success = Color(hex: 0x66BB6A)
    static let border = Color(hex: 0x2A2A2A)
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

// MARK: - Typography (Swiss International Style)

enum VTFont {
    static func title() -> Font { .system(size: 18, weight: .semibold, design: .default) }
    static func stat() -> Font { .system(size: 24, weight: .light, design: .default) }
    static func body() -> Font { .system(size: 15, weight: .regular, design: .default) }
    static func caption() -> Font { .system(size: 11, weight: .regular, design: .default) }
    static func mono() -> Font { .system(size: 12, weight: .regular, design: .monospaced) }
}

// MARK: - Key Cap View

struct KeyCap: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(VTColors.textMuted)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(VTColors.textMuted.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Record Button

struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void

    @State private var glowAnimation = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Glow ring when recording
                if isRecording {
                    Circle()
                        .fill(VTColors.recording.opacity(0.2))
                        .frame(width: 72, height: 72)
                        .scaleEffect(glowAnimation ? 1.15 : 0.95)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: glowAnimation)
                }

                // Main button circle
                Circle()
                    .fill(VTColors.recording)
                    .frame(width: 56, height: 56)
                    .shadow(color: VTColors.recording.opacity(isRecording ? 0.5 : 0.2), radius: isRecording ? 12 : 4)

                // Icon: mic when idle, stop square when recording
                if isRecording {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.white)
                        .frame(width: 18, height: 18)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear { glowAnimation = true }
        .onChange(of: isRecording) { _, newValue in
            glowAnimation = newValue
        }
    }
}

// MARK: - Waveform View

struct WaveformView: View {
    let levels: [Float]
    let barCount: Int = 50

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { i in
                let level = i < levels.count ? CGFloat(levels[i]) : 0
                RoundedRectangle(cornerRadius: 1)
                    .fill(VTColors.textSecondary.opacity(0.6))
                    .frame(width: 3, height: max(2, level * 32))
            }
        }
        .frame(height: 36)
        .animation(.easeOut(duration: 0.1), value: levels.count)
    }
}

// MARK: - State Strip

struct StateStrip: View {
    let state: RecordingState

    var color: Color {
        switch state {
        case .idle: return VTColors.border
        case .recording: return VTColors.recording
        case .transcribing: return VTColors.accent
        case .done: return VTColors.success
        }
    }

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: 3)
            .animation(.easeInOut(duration: 0.3), value: state)
    }
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
