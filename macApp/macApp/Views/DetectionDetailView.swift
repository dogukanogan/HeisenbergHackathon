import SwiftUI

struct DetectionDetailView: View {
    let detection: ExportData
    @State private var showJSON = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Acil Durum Tespiti")
                        .font(.largeTitle)
                        .bold()
                    
                    Text(detection.timestamp, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                // Tespit Edilen Sesler
                VStack(alignment: .leading, spacing: 16) {
                    Text("Tespit Edilen Sesler")
                        .font(.headline)
                    
                    ForEach(detection.detections) { det in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(det.rank). \(det.sound.capitalized)")
                                    .font(.body)
                                    .bold()
                                Text("Güven: \(Int(det.confidence * 100))%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            
                            // Confidence bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                    Rectangle()
                                        .fill(confidenceColor(det.confidence))
                                        .frame(width: geo.size.width * det.confidence)
                                }
                                .frame(height: 8)
                                .cornerRadius(4)
                            }
                            .frame(width: 100)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                Divider()
                
                // Profil Bilgileri
                VStack(alignment: .leading, spacing: 16) {
                    Text("Kullanıcı Profili")
                        .font(.headline)
                    
                    ProfileInfoView(profile: detection.profile)
                }
                
                Divider()
                
                // JSON Butonu
                Button {
                    showJSON = true
                } label: {
                    Label("JSON Verisini Görüntüle", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Detay")
        .sheet(isPresented: $showJSON) {
            JSONView(jsonData: detection)
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
}

struct ProfileInfoView: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            InfoRow(label: "Ad Soyad", value: profile.fullName)
            InfoRow(label: "Yaş", value: "\(profile.age)")
            InfoRow(label: "Kan Grubu", value: profile.bloodType)
            if let phone = profile.phone {
                InfoRow(label: "Telefon", value: phone)
            }
            
            if !profile.addresses.isEmpty {
                Divider()
                Text("Adresler")
                    .font(.subheadline)
                    .bold()
                    .padding(.top, 8)
                
                ForEach(profile.addresses) { address in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(address.label)
                            .font(.subheadline)
                            .bold()
                        Text("\(address.addressLine), \(address.district), \(address.city)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .bold()
        }
    }
}

struct JSONView: View {
    let jsonData: ExportData
    @Environment(\.dismiss) private var dismiss
    @State private var jsonString: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ScrollView {
                    Text(jsonString)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(jsonString, forType: .string)
                } label: {
                    Label("JSON'u Kopyala", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("JSON Verisi")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        dismiss()
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
