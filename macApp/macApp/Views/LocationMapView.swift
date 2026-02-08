import SwiftUI
import MapKit

struct LocationMapView: View {
    let location: LocationData
    @State private var region: MKCoordinateRegion
    @Environment(\.colorScheme) var colorScheme
    
    var isDark: Bool {
        colorScheme == .dark
    }
    
    init(location: LocationData) {
        self.location = location
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    private func updateRegion() {
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: location.latitude,
                    longitude: location.longitude
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ThemeColors.primaryRed, ThemeColors.primaryRedLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("Konum Bilgisi")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(ThemeColors.primaryText(isDark: isDark))
            }
            
            Map(coordinateRegion: $region, annotationItems: [MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))]) { annotation in
                MapMarker(
                    coordinate: annotation.coordinate,
                    tint: ThemeColors.primaryRed
                )
            }
            .frame(height: 300)
            .cornerRadius(16)
            .onAppear {
                // İlk yüklemede ve her görünümde konuma odaklan
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    updateRegion()
                }
            }
            .id("\(location.latitude)-\(location.longitude)") // Her yeni konumda view'ı yeniden oluştur
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
            .shadow(color: isDark ? Color.black.opacity(0.3) : Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enlem")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(ThemeColors.secondaryText(isDark: isDark))
                    Text(String(format: "%.6f", location.latitude))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(ThemeColors.primaryText(isDark: isDark))
                }
                
                Divider()
                    .frame(height: 30)
                    .background(ThemeColors.tertiaryText(isDark: isDark))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Boylam")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(ThemeColors.secondaryText(isDark: isDark))
                    Text(String(format: "%.6f", location.longitude))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(ThemeColors.primaryText(isDark: isDark))
                }
                
                Spacer()
                
                Button {
                    // Haritayı Apple Maps'te aç
                    let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)))
                    mapItem.name = "Acil Durum Konumu"
                    mapItem.openInMaps()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Haritada Aç")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [ThemeColors.primaryRed, ThemeColors.primaryRedLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
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
}

struct MapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
