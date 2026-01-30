import Foundation


protocol AudioClassifier {
    func classify() -> AIResult
}

final class MockAudioClassifier: AudioClassifier {
    func classify() -> AIResult {
        AIResult(eventType: "FIRE", confidence: 0.80)
    }
}
