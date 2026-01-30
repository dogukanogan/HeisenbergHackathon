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
    @State private var bloodType = ""
    @State private var birthDate = Date()

    @State private var enableMultipleAddresses = false
    @State private var addresses: [AddressForm] = [AddressForm(label: "Ev", addressLine: "", district: "", city: "")]

    @State private var phone = ""

    private var computedAge: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Ad", text: $firstName)
                    TextField("Soyad", text: $lastName)

                    DatePicker("Doğum Tarihi", selection: $birthDate, displayedComponents: .date)
                    Text("Yaş: \(computedAge)")
                        .foregroundStyle(DS.Colors.muted)

                    TextField("Kan Grubu", text: $bloodType)
                } header: {
                    Text("Kişisel Bilgiler")
                        .tint(DS.Colors.primary)
                }

                Section {
                    Toggle("Birden fazla adres", isOn: $enableMultipleAddresses)
                        .onChange(of: enableMultipleAddresses) { _, newValue in
                            if !newValue {
                                if let first = addresses.first { addresses = [first] }
                            }
                        }

                    ForEach($addresses) { $addr in
                        AddressFormView(address: $addr)
                    }

                    if enableMultipleAddresses {
                        Button {
                            addresses.append(AddressForm(label: "Yeni Adres", addressLine: "", district: "", city: ""))
                        } label: {
                            Label("Adres Ekle", systemImage: "plus")
                        }
                    }
                } header: {
                    Text("Adres")
                }

                Section {
                    TextField("Telefon", text: $phone)
                        .keyboardType(.phonePad)
                } header: {
                    Text("İletişim")
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
            .onAppear { loadProfile() }
        }
    }

    private func loadProfile() {
        guard let profile = ProfileStore.shared.load() else { return }
        firstName = profile.firstName
        lastName = profile.lastName
        bloodType = profile.bloodType
        birthDate = profile.birthDate
        phone = profile.phone ?? ""

        addresses = profile.addresses.map {
            AddressForm(id: $0.id, label: $0.label, addressLine: $0.addressLine, district: $0.district, city: $0.city)
        }
        enableMultipleAddresses = addresses.count > 1
        if addresses.isEmpty {
            addresses = [AddressForm(label: "Ev", addressLine: "", district: "", city: "")]
            enableMultipleAddresses = false
        }
    }

    private func saveProfile() {
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)

        let profile = UserProfile(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            birthDate: birthDate,
            bloodType: bloodType.trimmingCharacters(in: .whitespacesAndNewlines),
            addresses: addresses.map { $0.toAddress() },
            phone: trimmedPhone.isEmpty ? nil : trimmedPhone
        )

        ProfileStore.shared.save(profile)
    }
}
private struct AddressForm: Identifiable, Hashable {
    var id: UUID = UUID()
    var label: String
    var addressLine: String
    var district: String
    var city: String

    func toAddress() -> Address {
        Address(id: id, label: label, addressLine: addressLine, district: district, city: city)
    }
}

private struct AddressFormView: View {
    @Binding var address: AddressForm

    var body: some View {
        VStack(alignment: .leading) {
            TextField("Etiket", text: $address.label)
            TextField("Adres", text: $address.addressLine)
            TextField("İlçe", text: $address.district)
            TextField("Şehir", text: $address.city)
        }
    }
}

