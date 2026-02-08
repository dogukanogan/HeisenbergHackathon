import SwiftUI

struct DetectionListView: View {
    @StateObject private var dataManager = DataManager()
    @Environment(\.colorScheme) var colorScheme
    
    var isDark: Bool {
        colorScheme == .dark
    }
    
    var body: some View {
        NavigationSplitView {
            // Sol panel - Detection listesi
            ZStack {
                // Gradient arka plan
                LinearGradient(
                    colors: ThemeColors.backgroundGradient(isDark: isDark),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Başlık
                    VStack(spacing: 8) {
                        Text("Acil Durum Tespit Sistemi")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(ThemeColors.primaryText(isDark: isDark))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        Rectangle()
                            .fill(isDark ? Color.white.opacity(0.05) : Color.white.opacity(0.3))
                    )
                    
                    if dataManager.detections.isEmpty {
                        EmptyStateView(isDark: isDark)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(dataManager.detections) { detection in
                                    NavigationLink {
                                        DetectionDetailView(detection: detection)
                                    } label: {
                                        DetectionRowView(detection: detection, isDark: isDark)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
            .navigationTitle("Acil Durum Tespitleri")
            .navigationSplitViewColumnWidth(min: 540, ideal: 540, max: 540)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    // Başlat/Durdur butonu
                    Button {
                        if dataManager.isLoading {
                            dataManager.stopListening()
                        } else {
                            dataManager.startListening()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: dataManager.isLoading ? "stop.circle.fill" : "play.circle.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text(dataManager.isLoading ? "Durdur" : "Taramaya Başla")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(
                                colors: dataManager.isLoading ? 
                                    [ThemeColors.primaryRedDark, ThemeColors.primaryRed] :
                                    [ThemeColors.primaryRed, ThemeColors.primaryRedLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(6)
                        .shadow(color: ThemeColors.primaryRed.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    
                    // Temizle butonu
                    Button {
                        dataManager.clearAll()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Temizle")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(
                                colors: [ThemeColors.primaryRedDark, ThemeColors.primaryRed],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(6)
                        .shadow(color: ThemeColors.primaryRed.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .disabled(dataManager.detections.isEmpty)
                    .buttonStyle(.plain)
                }
            }
        } detail: {
            ZStack {
                LinearGradient(
                    colors: ThemeColors.backgroundGradient(isDark: isDark),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ThemeColors.primaryRed, ThemeColors.primaryRedLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("Bir detection seçin")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(ThemeColors.secondaryText(isDark: isDark))
                    Text("Detayları görmek için soldan bir öğe seçin")
                        .font(.system(size: 14))
                        .foregroundStyle(ThemeColors.tertiaryText(isDark: isDark))
                }
            }
        }
        .onAppear {
            dataManager.startListening()
        }
        .onDisappear {
            dataManager.stopListening()
        }
    }
}

struct EmptyStateView: View {
    let isDark: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                ThemeColors.primaryRed.opacity(0.2),
                                ThemeColors.primaryRedLight.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ThemeColors.primaryRed, ThemeColors.primaryRedLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("Henüz detection yok")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(ThemeColors.primaryText(isDark: isDark))
                
                Text("iOS uygulamasından veri bekleniyor...")
                    .font(.system(size: 16))
                    .foregroundStyle(ThemeColors.secondaryText(isDark: isDark))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct DetectionRowView: View {
    let detection: ExportData
    let isDark: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Sol tarafta ikon ve renk göstergesi
            if let topDetection = detection.detections.first {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: rankGradientColors(topDetection.rank),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: rankColor(topDetection.rank).opacity(0.4), radius: 10, x: 0, y: 3)
                    
                    Image(systemName: soundIcon(topDetection.sound))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            // Ana içerik
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let topDetection = detection.detections.first {
                            Text(soundDisplayName(topDetection.sound))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(ThemeColors.primaryText(isDark: isDark))
                            
                            // Uyarı mesajı
                            if let warning = getWarningMessage(topDetection.sound) {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(ThemeColors.primaryRed)
                                    Text(warning)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(ThemeColors.primaryRed)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Confidence badge
                    if let topDetection = detection.detections.first {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(confidenceColor(topDetection.confidence))
                                .frame(width: 7, height: 7)
                            Text("\(Int(topDetection.confidence * 100))%")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(confidenceColor(topDetection.confidence))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(confidenceColor(topDetection.confidence).opacity(0.15))
                        )
                    }
                }
                
                HStack(spacing: 12) {
                    // Kullanıcı bilgisi
                    HStack(spacing: 5) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(ThemeColors.secondaryText(isDark: isDark))
                        Text(detection.profile.fullName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(ThemeColors.secondaryText(isDark: isDark))
                    }
                    
                    Divider()
                        .frame(height: 12)
                        .background(ThemeColors.tertiaryText(isDark: isDark))
                    
                    // Zaman bilgisi
                    HStack(spacing: 5) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(ThemeColors.secondaryText(isDark: isDark))
                        Text(formatRelativeTime(detection.timestamp))
                            .font(.system(size: 12))
                            .foregroundStyle(ThemeColors.secondaryText(isDark: isDark))
                    }
                    
                    // Konum ikonu (varsa)
                    if let location = detection.location, location.isValid {
                        Divider()
                            .frame(height: 12)
                            .background(ThemeColors.tertiaryText(isDark: isDark))
                        
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(ThemeColors.primaryRed)
                            Text("Konum")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(ThemeColors.secondaryText(isDark: isDark))
                        }
                    }
                    
                    if detection.detections.count > 1 {
                        Spacer()
                        
                        // Toplam ses sayısı badge
                        HStack(spacing: 3) {
                            Image(systemName: "waveform")
                                .font(.system(size: 9))
                            Text("\(detection.detections.count) ses")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [ThemeColors.primaryRed, ThemeColors.primaryRedLight],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                }
            }
            
            Spacer()
            
            // Sağ ok ikonu
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(ThemeColors.tertiaryText(isDark: isDark))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: ThemeColors.cardBackground(isDark: isDark),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: ThemeColors.cardBorder(isDark: isDark),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: isDark ? Color.black.opacity(0.3) : Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func getWarningMessage(_ sound: String) -> String? {
        switch sound.lowercased() {
        case "crackling_fire", "fire":
            return "Kazazede yangında olabilir!"
        case "scream":
            return "Acil müdahale gerekebilir!"
        case "collapse":
            return "Bina çökmesi riski var!"
        case "siren":
            return "Kazazedenin bulunduğu ortamda siren sesi var!"
        case "car_horn":
            return "Trafik kazası olabilir!"
        case "door_wood_creaks":
            return "Zorla giriş olabilir!"
        case "engine":
            return "Araç kazası riski!"
        default:
            return nil
        }
    }
    
    private func soundIcon(_ sound: String) -> String {
        switch sound.lowercased() {
        case "crackling_fire", "fire":
            return "flame.fill"
        case "scream":
            return "exclamationmark.triangle.fill"
        case "siren":
            return "cross.case.fill" // Ambulans ikonu
        case "collapse":
            return "building.2.fill"
        case "car_horn", "horn":
            return "car.fill"
        case "door_wood_creaks", "door":
            return "door.left.hand.open"
        case "engine":
            return "engine.combustion.fill"
        default:
            return "waveform"
        }
    }
    
    private func soundDisplayName(_ sound: String) -> String {
        switch sound.lowercased() {
        case "crackling_fire":
            return "Yangın"
        case "scream":
            return "Çığlık"
        case "siren":
            return "Siren"
        case "collapse":
            return "Çökme"
        case "car_horn":
            return "Araba Korna"
        case "door_wood_creaks":
            return "Kapı Gıcırtısı"
        case "engine":
            return "Motor"
        default:
            return sound.capitalized
        }
    }
    
    private func rankColor(_ rank: Int) -> Color {
        // Sıralamaya göre renk: 1. kırmızı, 2. turuncu, 3. yeşil
        switch rank {
        case 1:
            return .red
        case 2:
            return .orange
        case 3:
            return .green
        default:
            // 3'ten sonraki sıralar için yeşil
            return .green
        }
    }
    
    private func rankGradientColors(_ rank: Int) -> [Color] {
        // Sıralamaya göre renk: 1. kırmızı, 2. turuncu, 3. yeşil
        switch rank {
        case 1:
            return [Color.red.opacity(0.9), Color.red.opacity(0.7)]
        case 2:
            return [Color.orange.opacity(0.9), Color.orange.opacity(0.7)]
        case 3:
            return [Color.green.opacity(0.9), Color.green.opacity(0.7)]
        default:
            // 3'ten sonraki sıralar için yeşil
            return [Color.green.opacity(0.9), Color.green.opacity(0.7)]
        }
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.9 {
            return .green
        } else if confidence >= 0.7 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        let minutes = Int(timeInterval / 60)
        let hours = Int(timeInterval / 3600)
        let days = Int(timeInterval / 86400)
        
        if days > 0 {
            return "\(days) gün önce"
        } else if hours > 0 {
            return "\(hours) saat önce"
        } else if minutes > 0 {
            return "\(minutes) dakika önce"
        } else {
            return "Az önce"
        }
    }
}
