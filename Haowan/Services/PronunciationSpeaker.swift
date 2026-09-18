import AVFoundation

/// Speaks a hanzi character aloud in Mandarin so the learner can hear its
/// pronunciation on the writing screen.
///
/// Uses `AVSpeechSynthesizer` (on-device text-to-speech). Note: Apple's
/// `Speech` framework is for the reverse — recognizing spoken audio as text —
/// so it isn't what's needed to *hear* a character.
@MainActor
@Observable
final class PronunciationSpeaker {
    @ObservationIgnored private let synthesizer = AVSpeechSynthesizer()
    @ObservationIgnored private var didConfigureSession = false

    /// True while audio is playing, so the UI can reflect the speaking state.
    private(set) var isSpeaking = false

    private let delegate = SpeakerDelegate()

    init() {
        delegate.owner = self
        synthesizer.delegate = delegate
    }

    /// Speak `text` in the given language. Mandarin (`zh-CN`) by default so a
    /// hanzi is read with its Mandarin reading rather than the device language.
    func speak(_ text: String, language: String = "zh-CN") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // A fresh tap restarts from the beginning rather than queueing.
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        configureSessionIfNeeded()

        let utterance = AVSpeechUtterance(string: trimmed)
        // Fall back to the synthesizer's default voice if a Mandarin voice
        // isn't installed, rather than failing silently.
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        synthesizer.speak(utterance)
    }

    // Pronunciation is core content, so it should be audible even when the
    // device is on silent. Configured lazily on first use.
    //
    // `AVAudioSession` activation blocks and warns if run on the main thread,
    // so the (thread-safe) session calls are dispatched off the main actor.
    private func configureSessionIfNeeded() {
        guard !didConfigureSession else { return }
        didConfigureSession = true
        Task.detached(priority: .userInitiated) {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try? session.setActive(true)
        }
    }

    fileprivate func updateSpeaking(_ speaking: Bool) {
        isSpeaking = speaking
    }
}

/// Bridges `AVSpeechSynthesizerDelegate` (an `NSObject` protocol) to the
/// `@Observable` speaker so `isSpeaking` tracks playback.
private final class SpeakerDelegate: NSObject, AVSpeechSynthesizerDelegate {
    weak var owner: PronunciationSpeaker?

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        MainActor.assumeIsolated { owner?.updateSpeaking(true) }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        MainActor.assumeIsolated { owner?.updateSpeaking(false) }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        MainActor.assumeIsolated { owner?.updateSpeaking(false) }
    }
}
