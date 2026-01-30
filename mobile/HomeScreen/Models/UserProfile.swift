//
//  UserProfile.swift
//  HomeScreen
//
//  Created by Görkem Çelik on 30.01.2026.
//

import Foundation

struct UserProfile: Codable, Equatable {
    var id: UUID = UUID()
    var firstName: String
    var lastName: String
    var age: Int
    var bloodType: String
    var addressLine: String
    var district: String
    var city: String
    var phone: String?

    var createdAt: Date = Date()

    var fullName: String { "\(firstName) \(lastName)" }
}
