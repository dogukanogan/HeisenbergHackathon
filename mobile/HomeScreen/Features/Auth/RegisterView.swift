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
    @State private var bloodType = ""

    @State private var birthDate = Date()

    @State private var enableMultipleAddresses = false

    // adresler
    @State private var addresses: [AddressForm] = [
        AddressForm(label: "Ev", addressLine: "", district: "", city: "")
    ]

    @State private var phone = ""

    private var computedAge: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }

    private var canSubmit: Bool {
        guard !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !bloodType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              computedAge >= 0
        else { return false }

        // en az 1 adres ve zorunlu alanları dolu olsun
        return addresses.allSatisfy { $0.isValid }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Kişisel Bilgiler") {
                    TextField("Ad", text: $firstName)
                    TextField("Soyad", text: $lastName)

                    DatePicker(
                        "Doğum Tarihi",
                        selection: $birthDate,
                        displayedComponents: .date
                    )

                    // yaş kullanıcıya bilgi olarak gösterilsin
                    Text("Yaş: \(computedAge)")
                        .foregroundStyle(DS.Colors.muted)

                    TextField("Kan Grubu (örn: A+)", text: $bloodType)
                        .textInputAutocapitalization(.characters)
                }

                Section("Adres") {
                    Toggle("Birden fazla adres eklemek istiyorum", isOn: $enableMultipleAddresses)
                        .onChange(of: enableMultipleAddresses) { _, newValue in
                            if !newValue {
                                // kapatınca sadece 1 adres bırak
                                if let first = addresses.first {
                                    addresses = [first]
                                } else {
                                    addresses = [AddressForm(label: "Ev", addressLine: "", district: "", city: "")]
                                }
                            } else {
                                // açınca en az 1 adres zaten var
                                if addresses.isEmpty {
                                    addresses = [AddressForm(label: "Ev", addressLine: "", district: "", city: "")]
                                }
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
                }

                Section("İletişim (Opsiyonel)") {
                    TextField("Telefon", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section {
                    Button {
                        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
                        let profile = UserProfile(
                            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                            birthDate: birthDate,
                            bloodType: bloodType.trimmingCharacters(in: .whitespacesAndNewlines),
                            addresses: addresses.map { $0.toModel() },
                            phone: trimmedPhone.isEmpty ? nil : trimmedPhone
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

// MARK: - Address Form helpers (UI için)
private struct AddressForm: Identifiable, Equatable {
    var id: UUID = UUID()
    var label: String
    var addressLine: String
    var district: String
    var city: String

    var isValid: Bool {
        !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !addressLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !district.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func toModel() -> Address {
        return Address(
            id: id,
            label: label,
            addressLine: addressLine,
            district: district,
            city: city
        )
    }
}

// MARK: - AddressFormView (UI parçası)
private struct AddressFormView: View {
    @Binding var address: AddressForm

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Etiket (örn: Ev, İş)", text: $address.label)
            TextField("Adres", text: $address.addressLine)
            HStack {
                TextField("İlçe", text: $address.district)
                TextField("Şehir", text: $address.city)
            }
        }
        .textInputAutocapitalization(.words)
        .autocorrectionDisabled()
        .padding(.vertical, 4)
    }
}

