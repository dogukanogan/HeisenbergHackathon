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
    @State private var addresses: [AddressForm] = [
        AddressForm(label: "Ev", addressLine: "", district: "", city: "")
    ]

    @State private var phone = ""

    private var computedAge: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }

    private var canSubmit: Bool {
        guard !firstName.trimmed.isEmpty,
              !lastName.trimmed.isEmpty,
              !bloodType.trimmed.isEmpty
        else { return false }
        return addresses.allSatisfy { $0.isValid }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.m) {
                    header

                    DSCard("Kişisel Bilgiler") {
                        VStack(spacing: DS.Spacing.s) {
                            DSField(title: "Ad", text: $firstName)
                            DSField(title: "Soyad", text: $lastName)

                            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                                Text("Doğum Tarihi")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.muted)

                                DatePicker("", selection: $birthDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()

                                Text("Yaş: \(computedAge)")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.muted)
                            }

                            DSField(title: "Kan Grubu", text: $bloodType)
                                .textInputAutocapitalization(.characters)
                        }
                    }

                    DSCard("Adres") {
                        VStack(spacing: DS.Spacing.s) {
                            Toggle("Birden fazla adres eklemek istiyorum", isOn: $enableMultipleAddresses)
                                .tint(DS.Colors.primary)

                            ForEach($addresses) { $addr in
                                AddressFormCard(address: $addr, canRemove: enableMultipleAddresses && addresses.count > 1) {
                                    addresses.removeAll { $0.id == addr.id }
                                }
                            }

                            if enableMultipleAddresses {
                                Button {
                                    addresses.append(AddressForm(label: "Yeni Adres", addressLine: "", district: "", city: ""))
                                } label: {
                                    Label("Adres Ekle", systemImage: "plus")
                                }
                                .foregroundStyle(DS.Colors.primary)
                            }
                        }
                    }

                    DSCard("İletişim (Opsiyonel)") {
                        DSField(title: "Telefon", text: $phone)
                            .keyboardType(.phonePad)
                    }

                    Button {
                        let trimmedPhone = phone.trimmed
                        let profile = UserProfile(
                            firstName: firstName.trimmed,
                            lastName: lastName.trimmed,
                            birthDate: birthDate,
                            bloodType: bloodType.trimmed,
                            addresses: addresses.map { $0.toModel() },
                            phone: trimmedPhone.isEmpty ? nil : trimmedPhone
                        )
                        ProfileStore.shared.save(profile)
                        onCompleted()
                    } label: {
                        Text("Kaydı Tamamla")
                    }
                    .buttonStyle(DSPrimaryButtonStyle())
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.5)

                    Spacer(minLength: DS.Spacing.xl)
                }
                .padding(DS.Spacing.l)
            }
            .background(DS.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Kayıt")
                        .font(DS.Typography.title)
                        .foregroundStyle(DS.Colors.text)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            HStack(spacing: DS.Spacing.s) {
                Circle()
                    .fill(DS.Colors.primarySoft)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(DS.Colors.primary)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Acil Durum Profili")
                        .font(DS.Typography.title)
                    Text("Bilgilerini kaydet, gerektiğinde hızlıca iletilebilsin.")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.muted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Small components

private struct DSField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text(title)
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Colors.muted)

            TextField("", text: $text)
                .textFieldStyle(.plain)
                .padding(12)
                .background(DS.Colors.background)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                        .stroke(DS.Colors.border, lineWidth: 1)
                )
        }
    }
}

private struct AddressFormCard: View {
    @Binding var address: AddressForm
    let canRemove: Bool
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: DS.Spacing.s) {
            HStack {
                Text("Adres")
                    .font(DS.Typography.section)
                Spacer()
                if canRemove {
                    Button(role: .destructive) { onRemove() } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            DSField(title: "Adres Adı (Ev/İş)", text: $address.label)
            DSField(title: "Adres", text: $address.addressLine)
            HStack(spacing: DS.Spacing.s) {
                DSField(title: "İlçe", text: $address.district)
                DSField(title: "İl", text: $address.city)
            }
        }
        .padding(DS.Spacing.m)
        .background(DS.Colors.primarySoft.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Address Form model (UI)
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
