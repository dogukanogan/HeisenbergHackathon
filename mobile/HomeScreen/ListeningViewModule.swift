import Foundation
import Combine

@MainActor
final class ListeningViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case listening
        case detected(topSounds: [TopSound])
        case error(String)
        
        struct TopSound: Equatable {
            let label: String
            let confidence: Double
        }
    }

    @Published private(set) var state: State = .idle

    private let classifier = SoundClassifierService()
    private let modelName: String = "model21"
    
    // 10 saniyelik dinleme için
    private var detectionResults: [(label: String, confidence: Double, timestamp: Date)] = []
    private var listeningStartTime: Date?
    private let listeningDuration: TimeInterval = 10.0 // 10 saniye
    private var listeningTask: Task<Void, Never>?
    
    // Sticky detection - yüksek confidence'lı sesi kilitle
    private var lockedSound: (label: String, confidence: Double, lockTime: Date)?
    private let lockDuration: TimeInterval = 3.0 // 3 saniye lock
    private let lockThreshold: Double = 0.75 // 0.75+ confidence için lock

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
        detectionResults = []
        listeningStartTime = Date()
        lockedSound = nil
        
        do {
            // Confidence threshold 0.5 - tüm sonuçları topla
            try await classifier.start(modelFileName: modelName, confidenceThreshold: 0.5) { [weak self] (results: [SoundClassifierService.Classification]) in
                guard let self, let top = results.first else { return }
                
                let now = Date()
                
                // Lock kontrolü - eğer bir ses lock'luysa ve süre dolmadıysa, sadece o sesi kabul et
                if let locked = self.lockedSound {
                    let timeSinceLock = now.timeIntervalSince(locked.lockTime)
                    if timeSinceLock < self.lockDuration {
                        // Lock süresi dolmadı - sadece lock'lu sesi kabul et
                        if top.identifier == locked.label {
                            self.detectionResults.append((
                                label: top.identifier,
                                confidence: top.confidence,
                                timestamp: now
                            ))
                        }
                        // Diğer sesleri ignore et
                        return
                    } else {
                        // Lock süresi doldu - temizle
                        self.lockedSound = nil
                    }
                }
                
                // Yüksek confidence'lı ses tespit edildiyse lock'la
                if top.confidence >= self.lockThreshold {
                    self.lockedSound = (label: top.identifier, confidence: top.confidence, lockTime: now)
                    print("🔒 Locked: \(top.identifier) (\(String(format: "%.1f", top.confidence * 100))%)")
                }
                
                // Tüm sonuçları topla (top 3'ü al)
                let top3 = Array(results.prefix(3))
                for result in top3 {
                    self.detectionResults.append((
                        label: result.identifier,
                        confidence: result.confidence,
                        timestamp: now
                    ))
                }
                
                print("🔊 Detected: \(top3.map { "\($0.identifier): \(String(format: "%.1f", $0.confidence * 100))%" }.joined(separator: ", "))")
                
                // İlk detection geldiğinde timer'ı başlat (eğer henüz başlamadıysa)
                if self.listeningTask == nil {
                    self.startEvaluationTimer()
                }
            }
            
            // İlk detection'ı beklemek için kısa bir süre bekle, sonra timer başlat
            // Eğer 2 saniye içinde detection gelmezse timer'ı başlat
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 saniye bekle
                
                guard let self, self.listeningTask == nil else { return }
                
                // Eğer hiç detection gelmediyse timer'ı başlat
                if self.detectionResults.isEmpty {
                    self.startEvaluationTimer()
                }
            }
        } catch {
            print("❌ Sound classification error: \(error.localizedDescription)")
            state = .error(error.localizedDescription)
        }
    }
    
    private func startEvaluationTimer() {
        // Timer zaten başladıysa tekrar başlatma
        guard listeningTask == nil else { return }
        
        listeningTask = Task { @MainActor [weak self] in
            guard let self else { return }
            
            // 10 saniye bekle
            try? await Task.sleep(nanoseconds: UInt64(self.listeningDuration * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            // En yüksek güven seviyeli sesleri bul (her ses için en yüksek confidence'ı al)
            var bestResults: [String: Double] = [:]
            for result in self.detectionResults {
                let current = bestResults[result.label] ?? 0.0
                if result.confidence > current {
                    bestResults[result.label] = result.confidence
                }
            }
            
            // En yüksek güven seviyeli 3 sesi al
            let top3 = bestResults.sorted { $0.value > $1.value }.prefix(3).map { 
                State.TopSound(label: $0.key, confidence: $0.value) 
            }
            
            if !top3.isEmpty {
                self.state = .detected(topSounds: top3)
                print("✅ 10 saniye tamamlandı. Top 3: \(top3.map { "\($0.label): \(String(format: "%.1f", $0.confidence * 100))%" }.joined(separator: ", "))")
            } else {
                self.state = .error("10 saniye boyunca ses tespit edilemedi")
            }
        }
    }

    func stop() {
        listeningTask?.cancel()
        listeningTask = nil
        classifier.stop()
        detectionResults = []
        listeningStartTime = nil
        lockedSound = nil
        state = .idle
    }
}
