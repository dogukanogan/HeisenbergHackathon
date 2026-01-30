import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var router: AppRouter
    @State private var showSettings = false

    var body: some View {
        GeometryReader { geo in
            ZStack {

                // DEV kırmızı acil alan
                Button {
                    // TODO: Acil durum aksiyonu buraya bağlanacak
                } label: {
                    ZStack {
                        Color.red
                            .ignoresSafeArea()

                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: geo.size.width * 0.22, weight: .bold))

                            Text("ACİL DURUM")
                                .font(.system(size: geo.size.width * 0.12, weight: .heavy))
                        }
                        .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)

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
    }
}
