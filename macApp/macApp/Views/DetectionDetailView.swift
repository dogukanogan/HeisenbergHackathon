import SwiftUI
import MapKit

struct DetectionDetailView: View {
    let detection: ExportData
    @State private var showJSON = false
    @Environment(\.colorScheme) var colorScheme
    
    var isDark: Bool {
        colorScheme == .dark
    }
    
    var body: some View {
        ZStack {
            // Gradient arka plan
            LinearGradient(
                colors: ThemeColors.backgroundGradient(isDark: isDark),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
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
                                        .frame(width: 64, height: 64)
                                        .shadow(color: rankColor(topDetection.rank).opacity(0.4), radius: 16, x: 0, y: 6)
                                    
                                    Image(systemName: soundIcon(topDetection.sound))
                                        .font(.system(size: 28, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Acil Durum Tespiti")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(ThemeColors.primaryText(isDark: isDark))
                                
                                if let topDetection = detection.detections.first, let warning = getWarningMessage(topDetection.sound) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(ThemeColors.primaryRed)
                                        Text(warning)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(ThemeColors.primaryRed)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(ThemeColors.primaryRed.opacity(0.15))
                                    )
                                }
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(ThemeColors.secondaryText(isDark: isDark))
                                    Text(formatDate(detection.timestamp))
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(ThemeColors.secondaryText(isDark: isDark))
                                    
                                    Text("•")
                                        .foregroundStyle(ThemeColors.tertiaryText(isDark: isDark))
                                    
                                    Text(formatTime(detection.timestamp))
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(ThemeColors.secondaryText(isDark: isDark))
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: ThemeColors.cardBackground(isDark: isDark),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
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
                    .shadow(color: isDark ? Color.black.opacity(0.3) : Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
                    
                    // Tespit Edilen Sesler
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "waveform.path")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [ThemeColors.primaryRed, ThemeColors.primaryRedLight],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            Text("Tespit Edilen Sesler")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(ThemeColors.primaryText(isDark: isDark))
                        }
                        
                        ForEach(detection.detections) { det in
                            DetectionCard(detection: det, isDark: isDark)
                        }
                    }
                    
                    // Konum Bilgisi
                    if let location = detection.location, location.isValid {
                        LocationMapView(location: location)
                            .id("\(detection.id)-\(location.latitude)-\(location.longitude)") // Her detection için unique ID
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "mappin.slash.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(ThemeColors.secondaryText(isDark: isDark))
                                Text("Konum Bilgisi")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(ThemeColors.primaryText(isDark: isDark))
                            }
                            
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(ThemeColors.secondaryText(isDark: isDark))
                                Text("Bu acil durum için konum bilgisi mevcut değil")
                                    .font(.system(size: 15))
                                    .foregroundStyle(ThemeColors.secondaryText(isDark: isDark))
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isDark ? Color.white.opacity(0.05) : Color.black.opacity(0.05))
                            )
                        }
                        .padding(24)
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
                        .shadow(color: isDark ? Color.black.opacity(0.3) : Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                    }
                    
                    // Profil Bilgileri
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [ThemeColors.primaryRed, ThemeColors.primaryRedLight],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            Text("Kullanıcı Profili")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(ThemeColors.primaryText(isDark: isDark))
                        }
                        
                        ProfileInfoView(profile: detection.profile, isDark: isDark)
                    }
                    
                    // JSON Butonu
                    Button {
                        showJSON = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("JSON Verisini Görüntüle")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [ThemeColors.primaryRed, ThemeColors.primaryRedLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: ThemeColors.primaryRed.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
        }
        .navigationTitle("Detay")
        .sheet(isPresented: $showJSON) {
            JSONView(jsonData: detection)
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
    
    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1:
            return .red
        case 2:
            return .orange
        case 3:
            return .green
        default:
            return .green
        }
    }
    
    private func rankGradientColors(_ rank: Int) -> [Color] {
        switch rank {
        case 1:
            return [Color.red.opacity(0.9), Color.red.opacity(0.7)]
        case 2:
            return [Color.orange.opacity(0.9), Color.orange.opacity(0.7)]
        case 3:
            return [Color.green.opacity(0.9), Color.green.opacity(0.7)]
        default:
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
}

struct DetectionCard: View {
    let detection: Detection
    let isDark: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Sol tarafta ikon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: rankGradientColors(detection.rank),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: rankColor(detection.rank).opacity(0.4), radius: 10, x: 0, y: 4)
                
                Text("\(detection.rank)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Ana içerik
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(soundDisplayName(detection.sound))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(ThemeColors.primaryText(isDark: isDark))
                    
                    Spacer()
                    
                    // Confidence badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(confidenceColor(detection.confidence))
                            .frame(width: 10, height: 10)
                        Text("\(Int(detection.confidence * 100))%")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(confidenceColor(detection.confidence))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(confidenceColor(detection.confidence).opacity(0.15))
                    )
                }
                
                // Confidence bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: rankGradientColors(detection.rank),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * detection.confidence)
                    }
                    .frame(height: 10)
                }
                .frame(height: 10)
            }
        }
        .padding(20)
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
        .shadow(color: isDark ? Color.black.opacity(0.3) : Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
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
            return ThemeColors.primaryRed
        }
    }
}

struct ProfileInfoView: View {
    let profile: UserProfile
    let isDark: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Temel Bilgiler
            VStack(alignment: .leading, spacing: 16) {
                InfoRow(icon: "person.fill", label: "Ad Soyad", value: profile.fullName, isDark: isDark)
                InfoRow(icon: "calendar", label: "Yaş", value: "\(profile.age)", isDark: isDark)
                InfoRow(icon: "drop.fill", label: "Kan Grubu", value: profile.bloodType, isDark: isDark)
                if let phone = profile.phone {
                    InfoRow(icon: "phone.fill", label: "Telefon", value: phone, isDark: isDark)
                }
            }
            
            if !profile.addresses.isEmpty {
                Divider()
                    .background(isDark ? Color.white.opacity(0.2) : Color.black.opacity(0.2))
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [ThemeColors.primaryRed, ThemeColors.primaryRedLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("Adresler")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(ThemeColors.primaryText(isDark: isDark))
                    }
                    
                    ForEach(profile.addresses) { address in
                        AddressCard(address: address, isDark: isDark)
                    }
                }
            }
        }
        .padding(24)
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
        .shadow(color: isDark ? Color.black.opacity(0.3) : Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

struct AddressCard: View {
    let address: Address
    let isDark: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ThemeColors.primaryRed.opacity(0.3), ThemeColors.primaryRedLight.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: "mappin")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ThemeColors.primaryRed, ThemeColors.primaryRedLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(address.label)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(ThemeColors.primaryText(isDark: isDark))
                Text("\(address.addressLine), \(address.district), \(address.city)")
                    .font(.system(size: 14))
                    .foregroundStyle(ThemeColors.secondaryText(isDark: isDark))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDark ? Color.white.opacity(0.05) : Color.black.opacity(0.05))
        )
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    let isDark: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ThemeColors.primaryRed.opacity(0.2), ThemeColors.primaryRedLight.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ThemeColors.primaryRed, ThemeColors.primaryRedLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(ThemeColors.secondaryText(isDark: isDark))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(ThemeColors.primaryText(isDark: isDark))
        }
    }
}

struct JSONView: View {
    let jsonData: ExportData
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var jsonString: String = ""
    @State private var copied = false
    
    var isDark: Bool {
        colorScheme == .dark
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient arka plan
                LinearGradient(
                    colors: ThemeColors.backgroundGradient(isDark: isDark),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ScrollView {
                        Text(jsonString)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isDark ? Color.black.opacity(0.3) : Color.white.opacity(0.8))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(jsonString, forType: .string)
                        withAnimation {
                            copied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                copied = false
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text(copied ? "Kopyalandı!" : "JSON'u Kopyala")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: copied ? 
                                    [Color.green.opacity(0.8), Color.green.opacity(0.6)] :
                                    [ThemeColors.primaryRed, ThemeColors.primaryRedLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: (copied ? Color.green : ThemeColors.primaryRed).opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .navigationTitle("JSON Verisi")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                            Text("Kapat")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                generateJSON()
            }
        }
    }
    
    private func generateJSON() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(jsonData),
           let string = String(data: data, encoding: .utf8) {
            jsonString = string
        } else {
            jsonString = "JSON oluşturulamadı"
        }
    }
}
