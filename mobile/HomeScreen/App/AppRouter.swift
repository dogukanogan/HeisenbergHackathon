//
//  AppRouter.swift
//  HomeScreen
//
//  Created by Görkem Çelik on 30.01.2026.
//

import SwiftUI
internal import Combine

@MainActor
final class AppRouter: ObservableObject {
    @Published var isRegistered: Bool

    init() {
        self.isRegistered = ProfileStore.shared.isRegistered
    }

    func refresh() {
        isRegistered = ProfileStore.shared.isRegistered
    }

    func completeRegistration() {
        isRegistered = true
    }

    func logoutToRegister() {
        ProfileStore.shared.clear()
        isRegistered = false
    }
}
