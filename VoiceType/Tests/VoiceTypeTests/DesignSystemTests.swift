import Testing
@testable import VoiceType

@Suite("Design System")
struct DesignSystemTests {
    @Test("Colors are defined")
    func colorsDefined() {
        #expect(VTColors.background != nil)
        #expect(VTColors.surface != nil)
        #expect(VTColors.textPrimary != nil)
        #expect(VTColors.textMuted != nil)
        #expect(VTColors.accent != nil)
        #expect(VTColors.recording != nil)
        #expect(VTColors.success != nil)
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
