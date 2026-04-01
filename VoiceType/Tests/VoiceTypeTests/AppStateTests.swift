import Testing
@testable import VoiceType

@Suite("App State")
struct AppStateTests {
    @Test("Initial state is idle and enabled")
    @MainActor
    func initialState() {
        let state = AppState()
        #expect(state.recordingState == .idle)
        #expect(state.isEnabled == true)
        #expect(state.lastTranscription == nil)
    }

    @Test("Recording state transitions work")
    @MainActor
    func recordingStateTransitions() {
        let state = AppState()
        state.recordingState = .recording
        #expect(state.recordingState == .recording)
        state.recordingState = .transcribing
        #expect(state.recordingState == .transcribing)
        state.recordingState = .done
        #expect(state.recordingState == .done)
    }

    @Test("Can toggle enabled state")
    @MainActor
    func toggleEnabled() {
        let state = AppState()
        state.isEnabled = false
        #expect(state.isEnabled == false)
    }
}
