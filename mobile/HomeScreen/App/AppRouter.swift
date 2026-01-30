//
//  AppRouter.swift
//  HomeScreen
//
//  Created by Görkem Çelik on 30.01.2026.
//

import SwiftUI
import Combine

@MainActor
final class AppRouter: ObservableObject {

    enum Route: Equatable {
        case splash
        case firstRunWelcome
        case register
        case home
    }

    @Published var route: Route = .splash

    private let hasLaunchedKey = "has_launched_before_v1"

    init() {
        start()
    }

    func start() {
        route = .splash

        Task { @MainActor in
            // Splash ekranda biraz dursun
            try? await Task.sleep(nanoseconds: 1_200_000_000)

            let hasLaunchedBefore = UserDefaults.standard.bool(forKey: hasLaunchedKey)
            let isRegistered = ProfileStore.shared.isRegistered

            if !hasLaunchedBefore {
                // İlk kez açıldı → welcome butonları görünsün
                UserDefaults.standard.set(true, forKey: hasLaunchedKey)
                route = .firstRunWelcome
                return
            }

            // İlk kez değil → kayıt varsa home, yoksa register
            route = isRegistered ? .home : .register
        }
    }

    // Welcome ekranındaki buton aksiyonları
    func goToRegister() {
        route = .register
    }

    func goToLogin() {
        // Login altyapısı yokken en mantıklısı register’a atmak
        route = .register
    }

    func completeRegistration() {
        route = .home
    }

    func resetProfile() {
        ProfileStore.shared.clear()
        route = .register
    }
}

