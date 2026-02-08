import Foundation
import Combine

@MainActor
final class DataManager: ObservableObject {
    @Published var detections: [ExportData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let bonjourService = BonjourService()
    
    init() {
        bonjourService.onDataReceived = { [weak self] data in
            Task { @MainActor in
                self?.handleReceivedData(data)
            }
        }
        
        // Örnek veriler ekle
        loadSampleData()
    }
    
    func startListening() {
        isLoading = true
        errorMessage = nil
        bonjourService.startBrowsing()
    }
    
    func stopListening() {
        bonjourService.stopBrowsing()
        isLoading = false
    }
    
    private func handleReceivedData(_ data: Data) {
        // Önce JSON string olarak kontrol et
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📄 Alınan JSON string uzunluğu: \(jsonString.count) karakter")
            print("📄 JSON string (tam): \(jsonString)")
            
            // JSON'un geçerli olup olmadığını kontrol et
            if let jsonData = jsonString.data(using: .utf8) {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    let exportData = try decoder.decode(ExportData.self, from: jsonData)
                    
                    // Gerçek veri geldiğinde örnek verileri temizle (sadece ilk gerçek veri için)
                    if detections.count == 3 && detections.allSatisfy({ $0.id.uuidString.hasPrefix("sample") }) {
                        detections.removeAll()
                    }
                    
                    detections.append(exportData)
                    detections.sort { $0.timestamp > $1.timestamp } // En yeni önce
                    
                    print("✅ Detection kaydedildi: \(exportData.detections.count) ses tespit edildi")
                    errorMessage = nil
                } catch {
                    print("❌ JSON parse error: \(error.localizedDescription)")
                    print("❌ JSON string: \(jsonString)")
                    errorMessage = "Veri parse edilemedi: \(error.localizedDescription)"
                }
            } else {
                print("❌ JSON string data'ya çevrilemedi")
                errorMessage = "Veri string'e çevrilemedi"
            }
        } else {
            print("❌ Data string'e çevrilemedi (UTF-8)")
            errorMessage = "Veri UTF-8 olarak decode edilemedi"
        }
    }
    
    func clearAll() {
        detections.removeAll()
        loadSampleData()
    }
    
    private func loadSampleData() {
        let sample1 = ExportData(
            id: UUID(uuidString: "sample-0001-0000-0000-000000000001") ?? UUID(),
            detections: [
                Detection(id: UUID(), sound: "crackling_fire", confidence: 0.95, rank: 1),
                Detection(id: UUID(), sound: "scream", confidence: 0.78, rank: 2),
                Detection(id: UUID(), sound: "door_wood_creaks", confidence: 0.45, rank: 3)
            ],
            profile: UserProfile(
                id: UUID(),
                firstName: "Ahmet",
                lastName: "Yılmaz",
                birthDate: Calendar.current.date(byAdding: .year, value: -35, to: Date()) ?? Date(),
                bloodType: "A+",
                addresses: [
                    Address(
                        id: UUID(),
                        label: "Ev",
                        addressLine: "Atatürk Caddesi No: 15",
                        district: "Kadıköy",
                        city: "İstanbul"
                    )
                ],
                phone: "+90 555 123 4567",
                createdAt: Date()
            ),
            timestamp: Date().addingTimeInterval(-3600), // 1 saat önce
            location: LocationData(latitude: 40.9889, longitude: 29.0244) // İstanbul Kadıköy koordinatları (Türkiye)
        )
        
        let sample2 = ExportData(
            id: UUID(uuidString: "sample-0002-0000-0000-000000000002") ?? UUID(),
            detections: [
                Detection(id: UUID(), sound: "siren", confidence: 0.92, rank: 1),
                Detection(id: UUID(), sound: "car_horn", confidence: 0.65, rank: 2),
                Detection(id: UUID(), sound: "engine", confidence: 0.52, rank: 3)
            ],
            profile: UserProfile(
                id: UUID(),
                firstName: "Ayşe",
                lastName: "Demir",
                birthDate: Calendar.current.date(byAdding: .year, value: -28, to: Date()) ?? Date(),
                bloodType: "0+",
                addresses: [
                    Address(
                        id: UUID(),
                        label: "İş",
                        addressLine: "Levent Mahallesi Büyükdere Cad. No: 100",
                        district: "Şişli",
                        city: "İstanbul"
                    ),
                    Address(
                        id: UUID(),
                        label: "Ev",
                        addressLine: "Bağdat Caddesi No: 45",
                        district: "Bostancı",
                        city: "İstanbul"
                    )
                ],
                phone: "+90 555 987 6543",
                createdAt: Date()
            ),
            timestamp: Date().addingTimeInterval(-7200), // 2 saat önce
            location: LocationData(latitude: 41.0766, longitude: 29.0230) // İstanbul Levent koordinatları (Türkiye)
        )
        
        let sample3 = ExportData(
            id: UUID(uuidString: "sample-0003-0000-0000-000000000003") ?? UUID(),
            detections: [
                Detection(id: UUID(), sound: "collapse", confidence: 0.88, rank: 1),
                Detection(id: UUID(), sound: "scream", confidence: 0.82, rank: 2),
                Detection(id: UUID(), sound: "crackling_fire", confidence: 0.71, rank: 3)
            ],
            profile: UserProfile(
                id: UUID(),
                firstName: "Mehmet",
                lastName: "Kaya",
                birthDate: Calendar.current.date(byAdding: .year, value: -42, to: Date()) ?? Date(),
                bloodType: "B+",
                addresses: [
                    Address(
                        id: UUID(),
                        label: "Ev",
                        addressLine: "Kızılay Meydanı No: 8",
                        district: "Çankaya",
                        city: "Ankara"
                    )
                ],
                phone: "+90 555 456 7890",
                createdAt: Date()
            ),
            timestamp: Date().addingTimeInterval(-10800), // 3 saat önce
            location: nil // Bu örnek için konum yok (test için)
        )
        
        detections = [sample1, sample2, sample3]
    }
}
