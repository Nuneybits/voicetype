import SwiftUI

struct ShareCardView: View {
    let wordCount: Int
    let timeSaved: String

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
        renderer.scale = 2.0
        return renderer.nsImage
    }
}
