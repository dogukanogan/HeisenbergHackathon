//
//  ProfileStore.swift
//  HomeScreen
//
//  Created by Görkem Çelik on 30.01.2026.
//

import Foundation

final class ProfileStore {
    static let shared = ProfileStore()
    private init() {}

    private let key = "user_profile_v1"

    func load() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(UserProfile.self, from: data)
    }

    func save(_ profile: UserProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    var isRegistered: Bool { load() != nil }
}
