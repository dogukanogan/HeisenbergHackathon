//
//  SettingsView.swift
//  HomeScreen
//
//  Created by Görkem Çelik on 30.01.2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: AppRouter
    


    @State private var firstName = ""
    @State private var lastName = ""
    @State private var birthDate = Date()

    // Kan grubu picker
    @State private var bloodType: String = "A+"

    @State private var addresses: [AddressForm] = [
        AddressForm(label: "Ev", addressLine: "", district: "", city: "")
    ]

    @State private var phone = ""
    @State private var showResetConfirm = false
    @State private var showLogoutConfirm = false


    private var computedAge: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }

    private var canSave: Bool {
        guard !firstName.trimmed.isEmpty,
              !lastName.trimmed.isEmpty
        else { return false }
        return addresses.allSatisfy { $0.isValid }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Kişisel Bilgiler") {
                    TextField("Ad", text: $firstName)
                    TextField("Soyad", text: $lastName)

                    DatePicker("Doğum Tarihi", selection: $birthDate, displayedComponents: .date)

                    Text("Yaş: \(computedAge)")
                        .foregroundStyle(.secondary)

                    Picker("Kan Grubu", selection: $bloodType) {
                        ForEach(["A+","A-","B+","B-","AB+","AB-","0+","0-"], id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }

                Section("Adres") {
                    ForEach($addresses) { $addr in
                        VStack(alignment: .leading, spacing: 10) {
                            TextField("Adres Adı (Ev/İş)", text: $addr.label)
                            TextField("Adres", text: $addr.addressLine)
                            TextField("İlçe", text: $addr.district)
                            TextField("İl", text: $addr.city)
                        }
                        .padding(.vertical, 6)
                    }
                    .onDelete { indexSet in
                        // En az 1 adres kalsın
                        if addresses.count > 1 {
                            addresses.remove(atOffsets: indexSet)
                        }
                    }

                    Button {
                        addresses.append(AddressForm(label: "Yeni Adres", addressLine: "", district: "", city: ""))
                    } label: {
                        Label("Adres Ekle", systemImage: "plus")
                    }
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
                    .disabled(!canSave)

                    Button("Profili Sıfırla", role: .destructive) {
                        showResetConfirm = true
                    }
                    
                    Button("Çıkış Yap", role: .destructive) {
                        showLogoutConfirm = true
                        }
                }
            }
            .tint(DS.Colors.primary)
            .navigationTitle("Ayarlar")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Geri") { dismiss() }
                }
            }
            .onAppear { loadProfile() }
            .alert("Profili sıfırlamak istiyor musunuz?", isPresented: $showResetConfirm) {
                Button("İptal", role: .cancel) { }
                Button("Evet, Sıfırla", role: .destructive) {
                    router.resetProfile()
                    dismiss()
                }
            } message: {
                Text("Tüm kayıtlı bilgiler silinecek ve giriş ekranına yönlendirileceksiniz.")
            }
            .alert("Çıkış yapmak istiyor musunuz?", isPresented: $showLogoutConfirm) {
                Button("İptal", role: .cancel) { }
                Button("Evet, Çıkış Yap", role: .destructive) {
                    router.logoutToWelcome()   // veya resetProfile() ile aynı davranış
                    dismiss()
                }
            } message: {
                Text("Giriş ekranına yönlendirileceksiniz.")
            }

        }
    }

    private func loadProfile() {
        guard let profile = ProfileStore.shared.load() else { return }

        firstName = profile.firstName
        lastName = profile.lastName
        birthDate = profile.birthDate
        bloodType = profile.bloodType
        phone = profile.phone ?? ""

        let mapped = profile.addresses.map {
            AddressForm(id: $0.id, label: $0.label, addressLine: $0.addressLine, district: $0.district, city: $0.city)
        }

        addresses = mapped.isEmpty ? [AddressForm(label: "Ev", addressLine: "", district: "", city: "")] : mapped
    }

    private func saveProfile() {
        let trimmedPhone = phone.trimmed

        let profile = UserProfile(
            firstName: firstName.trimmed,
            lastName: lastName.trimmed,
            birthDate: birthDate,
            bloodType: bloodType,
            addresses: addresses.map { $0.toModel() },
            phone: trimmedPhone.isEmpty ? nil : trimmedPhone
        )

        ProfileStore.shared.save(profile)
    }
}

// MARK: - Address Form (UI helper)
private struct AddressForm: Identifiable, Equatable {
    var id: UUID = UUID()
    var label: String
    var addressLine: String
    var district: String
    var city: String

    var isValid: Bool {
        !label.trimmed.isEmpty &&
        !addressLine.trimmed.isEmpty &&
        !district.trimmed.isEmpty &&
        !city.trimmed.isEmpty
    }

    func toModel() -> Address {
        Address(id: id, label: label.trimmed, addressLine: addressLine.trimmed, district: district.trimmed, city: city.trimmed)
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
