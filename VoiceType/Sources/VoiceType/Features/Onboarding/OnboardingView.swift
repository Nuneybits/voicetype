import SwiftUI
import AVFoundation

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var micPermissionGranted = false
    @State private var accessibilityGranted = false

    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: VTSpacing.xl) {
            switch currentPage {
            case 0: welcomePage
            case 1: permissionsPage
            default: readyPage
            }
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
            Button("Continue") { withAnimation { currentPage = 1 } }
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

            Button("Continue") { withAnimation { currentPage = 2 } }
                .buttonStyle(.borderedProminent)
                .disabled(!micPermissionGranted)
        }
        .padding(VTSpacing.xl)
    }

    private func permissionRow(
        icon: String,
        title: String,
        description: String,
        granted: Bool,
        action: @escaping () -> Void
    ) -> some View {
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
                Text("Your hotkey: \u{2325}Space")
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
