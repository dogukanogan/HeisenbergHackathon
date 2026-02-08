//
//  ContentView.swift
//  HomeScreen
//
//  Created by Görkem Çelik on 30.01.2026.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var router = AppRouter()
    @State private var showMustRegisterAlert = false
    @State private var mustRegisterMessage = "Lütfen önce kayıt olup bilgilerinizi girin."


    var body: some View {
        Group {
            switch router.route {
            case .splash:
                SplashView()

            case .firstRunWelcome:
                FirstRunWelcomeView(
                    onRegister: { router.goToRegister() },
                    onLogin: {
                        // Profil yoksa login saçma → uyarı göster
                        if !ProfileStore.shared.isRegistered {
                            showMustRegisterAlert = true
                        } else {
                            router.goToLogin()
                        }
                    }
                )

            case .register:
                RegisterView(onCompleted: {
                    router.completeRegistration()
                })
                .overlay(alignment: .topLeading) {
                    Button {
                        router.goToWelcome()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(.top, 14)
                    .padding(.leading, 14)
                }


            case .home:
                // Arkadaşın HomeView’ı gelince burayı HomeView() yapacağız.
                HomeView()
                    .environmentObject(router)
            }
        }
        .alert(
                    "Bilgi",
                    isPresented: $showMustRegisterAlert,
                    actions: {
                        Button("Tamam", role: .cancel) { }
                    },
                    message: {
                        Text("Lütfen önce kayıt olup bilgilerinizi girin.")
                    }
                    )
        .onAppear {
            // Uygulama açıldığında tüm izinleri iste
            Task {
                // Mikrofon izni
                _ = await AVAudioApplication.requestRecordPermission()
                
                // Konum izni
                LocationService.shared.requestPermission()
            }
        }
    }
    
}

// MARK: - Splash
private struct SplashView: View {
    var body: some View {
        ZStack {
            DS.Colors.primary.ignoresSafeArea()

            VStack(spacing: DS.Spacing.m) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(.white)

                Text("Hoş geldiniz")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("Acil Durum Uygulaması")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding()
        }
    }
}

// MARK: - Placeholder Home (arkadaşın HomeView gelince silinecek)
private struct HomePlaceholderView: View {
    var body: some View {
        VStack(spacing: DS.Spacing.m) {
            Text("Home (Placeholder)")
                .font(DS.Typography.title)
            Text("Arkadaşın HomeView ekleyince burası değişecek.")
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.muted)
        }
        .padding(DS.Spacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Colors.background)
    }
}
