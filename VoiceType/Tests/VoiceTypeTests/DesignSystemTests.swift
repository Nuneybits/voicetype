import Testing
import SwiftUI
@testable import VoiceType

@Suite("Design System")
struct DesignSystemTests {
    @Test("Colors are defined")
    func colorsDefined() {
        let colors: [Color] = [
            VTColors.background,
            VTColors.surface,
            VTColors.textPrimary,
            VTColors.textMuted,
            VTColors.accent,
            VTColors.recording,
            VTColors.success,
        ]
        #expect(colors.count == 7)
    }

    @Test("Spacing scale is correct")
    func spacingScale() {
        #expect(VTSpacing.xs == 4.0)
        #expect(VTSpacing.sm == 8.0)
        #expect(VTSpacing.md == 16.0)
        #expect(VTSpacing.lg == 24.0)
        #expect(VTSpacing.xl == 32.0)
    }
}
