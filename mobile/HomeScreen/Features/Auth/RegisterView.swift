//
//  RegisterView.swift
//  HomeScreen
//
//  Created by Görkem Çelik on 30.01.2026.
//

import SwiftUI

struct RegisterView: View {
    let onCompleted: () -> Void

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var ageText = ""
    @State private var bloodType = ""
    @State private var addressLine = ""
    @State private var district = ""
    @State private var city = ""
    @State private var phone = ""

    private var canSubmit: Bool {
        guard !firstName.isEmpty,
              !lastName.isEmpty,
              Int(ageText) != nil,
              !bloodType.isEmpty,
              !addressLine.isEmpty,
              !district.isEmpty,
              !city.isEmpty
        else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Kişisel Bilgiler") {
                    TextField("Ad", text: $firstName)
                    TextField("Soyad", text: $lastName)

                    TextField("Yaş", text: $ageText)
                        .keyboardType(.numberPad)

                    TextField("Kan Grubu (örn: A+)", text: $bloodType)
                        .textInputAutocapitalization(.characters)
                }

                Section("Adres") {
                    TextField("Adres", text: $addressLine)
                    TextField("İlçe", text: $district)
                    TextField("İl", text: $city)
                }

                Section("İletişim (Opsiyonel)") {
                    TextField("Telefon", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section {
                    Button {
                        let profile = UserProfile(
                            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                            age: Int(ageText) ?? 0,
                            bloodType: bloodType.trimmingCharacters(in: .whitespacesAndNewlines),
                            addressLine: addressLine.trimmingCharacters(in: .whitespacesAndNewlines),
                            district: district.trimmingCharacters(in: .whitespacesAndNewlines),
                            city: city.trimmingCharacters(in: .whitespacesAndNewlines),
                            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phone
                        )

                        ProfileStore.shared.save(profile)
                        onCompleted()
                    } label: {
                        Text("Kaydı Tamamla")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(!canSubmit)
                }
            }
            .navigationTitle("Kayıt")
        }
    }
}
