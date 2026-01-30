//
//  ContentView.swift
//  HomeScreen
//
//  Created by Görkem Çelik on 30.01.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var router = AppRouter()

    var body: some View {
        Group {
            switch router.route {
            case .splash:
                SplashView()

            case .firstRunWelcome:
                FirstRunWelcomeView(
                    onRegister: { router.goToRegister() },
                    onLogin: { router.goToLogin() }
                )

            case .register:
                RegisterView(onCompleted: {
                    router.completeRegistration()
                })

            case .home:
                // Arkadaşın HomeView’ı gelince burayı HomeView() yapacağız.
                HomePlaceholderView()
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
