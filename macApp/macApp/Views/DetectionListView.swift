import SwiftUI

struct DetectionListView: View {
    @StateObject private var dataManager = DataManager()
    
    var body: some View {
        NavigationSplitView {
            // Sol panel - Detection listesi
            List {
                if dataManager.detections.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "waveform.circle")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("Henüz detection yok")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("iOS uygulamasından veri bekleniyor...")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    ForEach(dataManager.detections) { detection in
                        NavigationLink {
                            DetectionDetailView(detection: detection)
                        } label: {
                            DetectionRowView(detection: detection)
                        }
                    }
                }
            }
            .navigationTitle("Acil Durum Tespitleri")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if dataManager.isLoading {
                            dataManager.stopListening()
                        } else {
                            dataManager.startListening()
                        }
                    } label: {
                        Label(
                            dataManager.isLoading ? "Durdur" : "Dinlemeyi Başlat",
                            systemImage: dataManager.isLoading ? "stop.circle.fill" : "play.circle.fill"
                        )
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button {
                        dataManager.clearAll()
                    } label: {
                        Label("Temizle", systemImage: "trash")
                    }
                    .disabled(dataManager.detections.isEmpty)
                }
            }
        } detail: {
            Text("Bir detection seçin")
                .foregroundStyle(.secondary)
        }
        .onAppear {
            dataManager.startListening()
        }
        .onDisappear {
            dataManager.stopListening()
        }
    }
}

struct DetectionRowView: View {
    let detection: ExportData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let topDetection = detection.detections.first {
                    Text(topDetection.sound.capitalized)
                        .font(.headline)
                    Spacer()
                    Text("\(Int(topDetection.confidence * 100))%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Text(detection.profile.fullName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(detection.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            if detection.detections.count > 1 {
                Text("+\(detection.detections.count - 1) ses daha")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
