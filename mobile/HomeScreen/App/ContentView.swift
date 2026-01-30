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
            if router.isRegistered {
                // Arkadaşın HomeView’ını burada çağıracağız.
                // Şimdilik geçici bir placeholder koyuyoruz.
                HomePlaceholderView()
            } else {
                RegisterView(onCompleted: {
                    router.completeRegistration()
                })
            }
        }
    }
}

// Arkadaşın HomeView’ı gelene kadar geçici ekran:
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
