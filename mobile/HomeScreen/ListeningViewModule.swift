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
    
    // Öncelikli sesler - model klasör isimleri
    private let prioritySounds: Set<String> = [
        "collapse",
        "thunderstorm",
        "scream",
        "water",
        "cry",
        "crying_baby",
        "crackling_fire"
    ]
    
    // Öncelikli ses için minimum confidence
    private let priorityThreshold: Double = 0.60
    
    // Lock için minimum confidence (öncelikli sesler için)
    private let lockThreshold: Double = 0.65
    
    // 12 saniyelik dinleme için (3 tur dinleme)
    private var detectionResults: [(label: String, confidence: Double, timestamp: Date)] = []
    private var listeningStartTime: Date?
    private let listeningDuration: TimeInterval = 12.0 // 12 saniye (3 tur)
    private var listeningTask: Task<Void, Never>?
    
    // Sticky detection - öncelikli sesler için lock
    private var lockedSound: (label: String, confidence: Double, lockTime: Date)?
    private let lockDuration: TimeInterval = 4.0 // 4 saniye lock

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
            // Confidence threshold
            try await classifier.start(modelFileName: modelName, confidenceThreshold: 0.6) { [weak self] (results: [SoundClassifierService.Classification]) in
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
                
                // Öncelikli ses ve yeterli confidence varsa lock'la
                let isPrioritySound = self.isPrioritySound(top.identifier)
                if isPrioritySound && top.confidence >= self.lockThreshold {
                    self.lockedSound = (label: top.identifier, confidence: top.confidence, lockTime: now)
                    print("🔒 Priority sound locked: \(top.identifier) (\(String(format: "%.1f", top.confidence * 100))%)")
                }
                
                // TÜM sonuçları logla - model'in döndürdüğü gerçek isimleri görmek için
                print("🔊 Model sonuçları (TÜMÜ):")
                for (index, result) in results.enumerated() {
                    let isPriority = self.isPrioritySound(result.identifier)
                    print("  \(index + 1). \(result.identifier): \(String(format: "%.1f", result.confidence * 100))%\(isPriority ? " [PRIORITY ✅]" : "")")
                }
                
                // Tüm sonuçları topla (top 5'e çıkarıldı - daha fazla veri için)
                let top5 = Array(results.prefix(5))
                for result in top5 {
                    self.detectionResults.append((
                        label: result.identifier,
                        confidence: result.confidence,
                        timestamp: now
                    ))
                }
                
                // Debug: Top 3 özet
                let top3 = Array(results.prefix(3))
                let top3Info = top3.map { result in
                    "\(result.identifier): \(String(format: "%.1f", result.confidence * 100))%"
                }
                print("🔊 Top 3: \(top3Info.joined(separator: ", "))")
                
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
            
            // 12 saniye bekle (3 tur dinleme)
            try? await Task.sleep(nanoseconds: UInt64(self.listeningDuration * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            // Her ses için tüm confidence değerlerini topla (frekans ve ortalama için)
            var soundData: [String: (confidences: [Double], timestamps: [Date])] = [:]
            for result in self.detectionResults {
                if soundData[result.label] == nil {
                    soundData[result.label] = (confidences: [], timestamps: [])
                }
                soundData[result.label]?.confidences.append(result.confidence)
                soundData[result.label]?.timestamps.append(result.timestamp)
            }
            
            // Her ses için istatistikleri hesapla
            struct SoundStats {
                let label: String
                let maxConfidence: Double
                let avgConfidence: Double
                let frequency: Int
                let isPriority: Bool
                
                // Öncelikli sesler için: (ortalama * 0.6 + max * 0.4) * frekans_çarpanı (daha agresif)
                // Diğer sesler için: (ortalama * 0.5 + max * 0.5) * frekans_çarpanı
                var score: Double {
                    let frequencyMultiplier = min(Double(frequency) / 2.0, 2.0) // Max 2.0x çarpan (frekans önemli!)
                    
                    if isPriority {
                        // Öncelikli sesler için frekans daha önemli
                        return (avgConfidence * 0.6 + maxConfidence * 0.4) * frequencyMultiplier * 1.2 // Bonus çarpan
                    } else {
                        return (avgConfidence * 0.5 + maxConfidence * 0.5) * frequencyMultiplier
                    }
                }
            }
            
            var allStats: [SoundStats] = []
            
            for (label, data) in soundData {
                let confidences = data.confidences
                let maxConf = confidences.max() ?? 0.0
                let avgConf = confidences.reduce(0.0, +) / Double(confidences.count)
                let frequency = confidences.count
                let isPriority = self.isPrioritySound(label)
                
                allStats.append(SoundStats(
                    label: label,
                    maxConfidence: maxConf,
                    avgConfidence: avgConf,
                    frequency: frequency,
                    isPriority: isPriority
                ))
            }
            
            print("\n📊 ========== 12 SANİYE SONU ANALİZ ==========")
            print("📊 Toplam \(allStats.count) farklı ses algılandı\n")
            
            // Öncelikli sesleri ve diğer sesleri ayır
            var priorityStats: [SoundStats] = []
            var otherStats: [SoundStats] = []
            
            for stats in allStats {
                // Öncelikli ses kriteri: öncelikli ses olmalı VE (ortalama 0.60+ VEYA 2+ kere algılandıysa ve ortalama 0.50+)
                let isPriorityCandidate = stats.isPriority && (
                    stats.avgConfidence >= self.priorityThreshold ||
                    (stats.frequency >= 2 && stats.avgConfidence >= 0.50) ||
                    (stats.frequency >= 1 && stats.avgConfidence >= 0.65)
                )
                
                if isPriorityCandidate {
                    priorityStats.append(stats)
                    print("📊 [PRIORITY] '\(stats.label)' - Avg: \(String(format: "%.1f", stats.avgConfidence * 100))%, Max: \(String(format: "%.1f", stats.maxConfidence * 100))%, Freq: \(stats.frequency), Score: \(String(format: "%.3f", stats.score))")
                } else {
                    otherStats.append(stats)
                    print("📊 [OTHER] '\(stats.label)' - Avg: \(String(format: "%.1f", stats.avgConfidence * 100))%, Max: \(String(format: "%.1f", stats.maxConfidence * 100))%, Freq: \(stats.frequency), Score: \(String(format: "%.3f", stats.score))")
                }
            }
            
            // Öncelikli sesleri skor'a göre sırala (en yüksek önce)
            priorityStats.sort { $0.score > $1.score }
            
            // Diğer sesleri skor'a göre sırala
            otherStats.sort { $0.score > $1.score }
            
            print("\n🎯 ========== FİNAL SIRALAMA ==========")
            
            // Önce öncelikli sesleri ekle, sonra diğer sesleri ekle (HER ZAMAN 3 SES)
            var finalResults: [State.TopSound] = []
            
            // Öncelikli sesleri ekle (en üste yapıştır - skor'a göre)
            for (index, priority) in priorityStats.enumerated() {
                if finalResults.count >= 3 { break }
                finalResults.append(State.TopSound(
                    label: priority.label,
                    confidence: priority.avgConfidence
                ))
                print("🎯 \(finalResults.count). [PRIORITY] \(priority.label) - Avg: \(String(format: "%.1f", priority.avgConfidence * 100))%, Freq: \(priority.frequency), Score: \(String(format: "%.3f", priority.score))")
            }
            
            // Kalan yerleri diğer seslerle doldur (HER ZAMAN 3 SES GÖSTER)
            for other in otherStats {
                if finalResults.count >= 3 { break }
                finalResults.append(State.TopSound(
                    label: other.label,
                    confidence: other.avgConfidence
                ))
                print("🎯 \(finalResults.count). [OTHER] \(other.label) - Avg: \(String(format: "%.1f", other.avgConfidence * 100))%, Freq: \(other.frequency), Score: \(String(format: "%.3f", other.score))")
            }
            
            // Eğer hala 3'ten az ses varsa, en yüksek confidence'lı sesleri ekle
            if finalResults.count < 3 {
                let remaining = allStats.filter { stats in
                    !finalResults.contains { $0.label == stats.label }
                }.sorted { $0.maxConfidence > $1.maxConfidence }
                
                for stats in remaining {
                    if finalResults.count >= 3 { break }
                    finalResults.append(State.TopSound(
                        label: stats.label,
                        confidence: stats.avgConfidence
                    ))
                    print("🎯 \(finalResults.count). [FALLBACK] \(stats.label) - Avg: \(String(format: "%.1f", stats.avgConfidence * 100))%")
                }
            }
            
            print("🎯 ======================================\n")
            
            if !finalResults.isEmpty {
                self.state = .detected(topSounds: finalResults)
                let priorityCount = priorityStats.count
                print("✅ 12 saniye tamamlandı. Top \(finalResults.count): \(finalResults.map { "\($0.label): \(String(format: "%.1f", $0.confidence * 100))%" }.joined(separator: ", "))")
                if priorityCount > 0 {
                    print("🎯 Öncelikli sesler: \(priorityCount) adet")
                }
            } else {
                self.state = .error("12 saniye boyunca ses tespit edilemedi")
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
    
    // Ses isminin öncelikli ses olup olmadığını kontrol et (case-insensitive, esnek eşleştirme)
    private func isPrioritySound(_ soundLabel: String) -> Bool {
        let lowercased = soundLabel.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Direkt eşleşme
        if prioritySounds.contains(lowercased) {
            return true
        }
        
        // Kısmi eşleşme - underscore'ları boşluk veya tire ile değiştir
        let normalized = lowercased.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ")
        
        for prioritySound in prioritySounds {
            let priorityLower = prioritySound.lowercased()
            let priorityNormalized = priorityLower.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ")
            
            // Eğer ses ismi öncelikli sesi içeriyorsa veya öncelikli ses ses ismini içeriyorsa
            if normalized.contains(priorityNormalized) || priorityNormalized.contains(normalized) {
                return true
            }
        }
        
        return false
    }
}
