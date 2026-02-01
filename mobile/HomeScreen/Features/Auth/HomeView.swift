import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var listeningViewModel = ListeningViewModel()
    @State private var showSettings = false
    @State private var showDetectionAlert = false
    @State private var showJSONView = false
    @State private var detectedTopSounds: [ListeningViewModel.State.TopSound] = []
    @State private var jsonData: String = ""
    @State private var listeningProgress: Double = 0.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Ana acil durum butonu
                Button {
                    listeningViewModel.toggle()
                } label: {
                    ZStack {
                        // Dinleme durumuna göre renk değişimi
                        Group {
                            switch listeningViewModel.state {
                            case .listening:
                                Color.orange
                            case .detected:
                                Color.green
                            case .error:
                                Color.gray
                            default:
                                DS.Colors.primary
                            }
                        }
                        .ignoresSafeArea()

                        VStack(spacing: 16) {
                            // İkon ve durum
                            Group {
                                switch listeningViewModel.state {
                                case .idle:
                                    Image(systemName: "exclamationmark.triangle.fill")
                                case .listening:
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(1.5)
                                case .detected:
                                    Image(systemName: "checkmark.circle.fill")
                                case .error:
                                    Image(systemName: "exclamationmark.circle.fill")
                                }
                            }
                            .font(.system(size: geo.size.width * 0.22, weight: .bold))
                            .foregroundStyle(.white)

                            // Metin
                            Group {
                                switch listeningViewModel.state {
                                case .idle:
                                    Text("ACİL DURUM")
                                case .listening:
                                    Text("DİNLENİYOR...")
                                case .detected:
                                    Text("TESPİT EDİLDİ!")
                                case .error:
                                    Text("HATA")
                                }
                            }
                            .font(.system(size: geo.size.width * 0.12, weight: .heavy))
                            .foregroundStyle(.white)
                            
                            // Detay bilgisi
                            if case .detected = listeningViewModel.state {
                                Text("ACİL DURUM ALGILANDI")
                                    .font(.system(size: geo.size.width * 0.06, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                Text("Gerekli yardımlar yola çıkıyor")
                                    .font(.system(size: geo.size.width * 0.04, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            
                            // Dinleme progress (10 saniye)
                            if case .listening = listeningViewModel.state {
                                ProgressView(value: listeningProgress, total: 1.0)
                                    .progressViewStyle(.linear)
                                    .frame(width: geo.size.width * 0.6)
                                    .tint(.white)
                                    .padding(.top, 20)
                            }
                            
                            // Hata mesajı
                            if case .error(let message) = listeningViewModel.state {
                                Text(message)
                                    .font(.system(size: geo.size.width * 0.05, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .onChange(of: listeningViewModel.state) { oldValue, newValue in
                    if case .detected(let topSounds) = newValue {
                        guard let top = topSounds.first else { return }
                        
                        detectedTopSounds = topSounds
                        
                        // JSON verisini hazırla (top 3 ses + profil)
                        prepareJSONData(topSounds: topSounds)
                        
                        // Her zaman alert göster
                        showDetectionAlert = true
                        
                        // En yüksek güven seviyesi 90'ın üstündeyse bildirim gönder
                        if top.confidence >= 0.90 {
                            Task {
                                let granted = await NotificationService.shared.requestPermission()
                                if granted {
                                    NotificationService.shared.sendDetectionNotification(
                                        soundLabel: top.label,
                                        confidence: top.confidence
                                    )
                                }
                            }
                        }
                    } else if case .listening = newValue {
                        // Dinleme başladığında progress'i başlat
                        startListeningProgress()
                    } else if case .idle = newValue {
                        listeningProgress = 0.0
                    }
                }

                // Sağ üst küçük Settings
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 14)
                        .padding(.trailing, 14)
                    }
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(router)
        }
        .alert("Acil Durum Algılandı", isPresented: $showDetectionAlert) {
            Button("Detayları Gör") {
                showJSONView = true
            }
            Button("Tamam", role: .cancel) {
                // Dinlemeyi durdur
                listeningViewModel.stop()
            }
        } message: {
            Text("Acil durum algılandı. Gerekli yardımlar yola çıkıyor.")
        }
        .sheet(isPresented: $showJSONView) {
            JSONExportView(jsonData: jsonData)
        }
        .onChange(of: showJSONView) { oldValue, newValue in
            // JSON view kapatıldığında state'i sıfırla
            if !newValue && listeningViewModel.state != .idle {
                listeningViewModel.stop()
            }
        }
    }
    
    private func startListeningProgress() {
        listeningProgress = 0.0
        Task {
            let duration: TimeInterval = 10.0
            let steps = 100
            let stepDuration = duration / Double(steps)
            
            for i in 0...steps {
                try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
                await MainActor.run {
                    listeningProgress = Double(i) / Double(steps)
                }
            }
        }
    }
    
    private func prepareJSONData(topSounds: [ListeningViewModel.State.TopSound]) {
        // Bonjour server'ı başlat (eğer başlamadıysa)
        BonjourServer.shared.start()
        
        guard let profile = ProfileStore.shared.load() else {
            // Profil yoksa sadece detection bilgileri
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            
            struct DetectionOnly: Codable {
                let detections: [Detection]
                let timestamp: Date
                let error: String
            }
            
            struct Detection: Codable {
                let sound: String
                let confidence: Double
                let rank: Int
            }
            
            let detections = topSounds.enumerated().map { index, sound in
                Detection(sound: sound.label, confidence: sound.confidence, rank: index + 1)
            }
            
            let data = DetectionOnly(
                detections: detections,
                timestamp: Date(),
                error: "Profil bilgisi bulunamadı"
            )
            
            if let encoded = try? encoder.encode(data),
               let jsonString = String(data: encoded, encoding: .utf8) {
                jsonData = jsonString
            }
            return
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        struct ExportData: Codable {
            let detections: [Detection]
            let profile: UserProfile
            let timestamp: Date
        }
        
        struct Detection: Codable {
            let sound: String
            let confidence: Double
            let rank: Int
        }
        
        // Top 3 sesi rank ile birlikte ekle
        let detections = topSounds.enumerated().map { index, sound in
            Detection(sound: sound.label, confidence: sound.confidence, rank: index + 1)
        }
        
        let exportData = ExportData(
            detections: detections,
            profile: profile,
            timestamp: Date()
        )
        
        if let data = try? encoder.encode(exportData),
           let jsonString = String(data: data, encoding: .utf8) {
            jsonData = jsonString
            print("📄 JSON hazırlandı (top \(detections.count) ses + profil)")
            
            // macOS uygulamasına gönder
            BonjourServer.shared.sendJSON(jsonString)
        } else {
            jsonData = "JSON oluşturulamadı"
        }
    }
}
