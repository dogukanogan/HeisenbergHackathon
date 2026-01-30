//
//  SettingsView.swift
//  HomeScreen
//
//  Created by Görkem Çelik on 30.01.2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var ageText = ""
    @State private var bloodType = ""
    @State private var addressLine = ""
    @State private var district = ""
    @State private var city = ""
    @State private var phone = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Kişisel Bilgiler") {
                    TextField("Ad", text: $firstName)
                    TextField("Soyad", text: $lastName)

                    TextField("Yaş", text: $ageText)
                        .keyboardType(.numberPad)

                    TextField("Kan Grubu", text: $bloodType)
                }

                Section("Adres") {
                    TextField("Adres", text: $addressLine)
                    TextField("İlçe", text: $district)
                    TextField("İl", text: $city)
                }

                Section("İletişim") {
                    TextField("Telefon", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section {
                    Button("Kaydet") {
                        saveProfile()
                        dismiss()
                    }

                    Button("Profili Sıfırla", role: .destructive) {
                        ProfileStore.shared.clear()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Ayarlar")
            .onAppear {
                loadProfile()
            }
        }
    }

    private func loadProfile() {
        guard let profile = ProfileStore.shared.load() else { return }

        firstName = profile.firstName
        lastName = profile.lastName
        ageText = String(profile.age)
        bloodType = profile.bloodType
        addressLine = profile.addressLine
        district = profile.district
        city = profile.city
        phone = profile.phone ?? ""
    }

    private func saveProfile() {
        let profile = UserProfile(
            firstName: firstName,
            lastName: lastName,
            age: Int(ageText) ?? 0,
            bloodType: bloodType,
            addressLine: addressLine,
            district: district,
            city: city,
            phone: phone.isEmpty ? nil : phone
        )

        ProfileStore.shared.save(profile)
    }
}
