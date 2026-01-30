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
        let isRegistered = ProfileStore.shared.isRegistered

        // ✅ Kayıtlıysa hiç splash gösterme, direkt home
        if isRegistered {
            route = .home
            return
        }

        // Kayıtlı değilse mevcut akış devam
        route = .splash

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)

            let hasLaunchedBefore = UserDefaults.standard.bool(forKey: hasLaunchedKey)

            if !hasLaunchedBefore {
                UserDefaults.standard.set(true, forKey: hasLaunchedKey)
                route = .firstRunWelcome
                return
            }

            // kayıt yoksa her zaman welcome
            route = .firstRunWelcome
        }
    }


    // Welcome ekranındaki buton aksiyonları
    func goToRegister() {
        route = .register
    }

    // ✅ Geri dönmek için: Register/Login ekranından Welcome'a
    func goToWelcome() {
        route = .firstRunWelcome
    }

    func goToLogin() {
        // Login altyapısı yokken istenen davranış: home'a girsin
        route = .home
    }

    func completeRegistration() {
        route = .home
    }

    // ✅ Profil sıfırlayınca tekrar welcome'a dön (kayıt ekranına değil)
    func resetProfile() {
        ProfileStore.shared.clear()
        route = .firstRunWelcome
    }

    // ✅ Home'dan çıkış gibi kullanmak istersen (opsiyonel)
    func logoutToWelcome() {
        ProfileStore.shared.clear()
        route = .firstRunWelcome
    }
}
