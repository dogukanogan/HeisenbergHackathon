import Foundation
import Combine


@MainActor
final class EmergencyFlowController: ObservableObject {
    @Published var isListening: Bool = false
    @Published var liveLevel: Float = 0
    @Published var detectedEventType: String? = nil

    private let audio = AudioLevelMonitor()
    private var timer: Timer?
    private var samples: [Float] = []

    // AI hazır olana kadar mock
    private let classifier: AudioClassifier = MockAudioClassifier()

    func startListening(durationSeconds: Int = 10) {
        Task {
            let granted = await audio.requestPermission()
            if !granted {
                print("Mikrofon izni yok")
                return
            }

            do {
                try await MainActor.run {
                    try audio.start()
                }
            } catch {
                print("Audio start error:", error)
                return
            }


            samples.removeAll()
            detectedEventType = nil
            isListening = true
            liveLevel = 0

            var ticks = 0
            timer?.invalidate()

            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] t in
                guard let self = self else { return }

                // Timer actor dışından çalışır; UI state'lerini main actor'a taşıyoruz
                Task { @MainActor in
                    self.audio.updateMeters()
                    self.liveLevel = self.audio.level
                    self.samples.append(self.liveLevel)

                    ticks += 1
                    if ticks >= durationSeconds * 10 {
                        t.invalidate()
                        self.finishListeningAndDecide()
                    }
                }
            }
        }
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
        audio.stop()

        isListening = false
        liveLevel = 0
        detectedEventType = nil

        NotificationService.shared.cancelEmergency()
    }

    private func finishListeningAndDecide() {
        audio.stop()
        isListening = false

        let avg = samples.isEmpty ? 0 : (samples.reduce(0, +) / Float(samples.count))
        print("Avg level:", avg)

        // Sessizse event yok
        guard avg > 0.20 else {
            detectedEventType = "NO_EVENT"
            return
        }

        // Ses var -> şimdilik mock classifier ile tür belirle
        let result = classifier.classify()
        detectedEventType = result.eventType
        if result.eventType != "NO_EVENT" {
            NotificationService.shared.startEmergencyNotifications()
        }

        }
    }

