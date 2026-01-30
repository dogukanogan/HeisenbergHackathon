//
//  UserProfile.swift
//  HomeScreen
//
//  Created by Görkem Çelik on 30.01.2026.
//

import Foundation

struct Address: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var label: String          // örn: "Ev", "İş", "Annemin evi"
    var addressLine: String
    var district: String
    var city: String
}

struct UserProfile: Codable, Equatable {
    var id: UUID = UUID()
    var firstName: String
    var lastName: String

    // artık yaş yerine doğum tarihi tutuyoruz
    var birthDate: Date

    var bloodType: String

    // birden fazla adres
    var addresses: [Address]

    var phone: String?
    var createdAt: Date = Date()

    var fullName: String { "\(firstName) \(lastName)" }

    // Yaşı her zaman doğum tarihinden hesapla
    var age: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }
}
