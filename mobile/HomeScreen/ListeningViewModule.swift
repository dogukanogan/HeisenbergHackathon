import Foundation

@MainActor
final class ListeningViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case listening
        case detected(label: String, confidence: Double)
        case error(String)
    }

    @Published private(set) var state: State = .idle

    private let classifier = SoundClassifierService()
    private let modelName: String = "model21"

    func toggle() {
        switch state {
        case .idle, .detected, .error:
            Task { await start() }
        case .listening:
            stop()
        }
    }

    func start() async {
        state = .listening
        do {
            try await classifier.start(modelFileName: modelName, confidenceThreshold: 0.75) { [weak self] results in
                guard let top = results.first else { return }
                self?.state = .detected(label: top.identifier, confidence: top.confidence)

                // Şimdilik debug log (sonraki adım: JSON event)
                // print("Detected:", top.identifier, top.confidence)
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func stop() {
        classifier.stop()
        state = .idle
    }
}
