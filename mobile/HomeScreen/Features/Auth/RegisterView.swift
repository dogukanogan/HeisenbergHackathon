//
//  RegisterView.swift
//  HomeScreen
//
//  Created by Görkem Çelik on 30.01.2026.
//

import SwiftUI

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

struct RegisterView: View {
    let onCompleted: () -> Void

    @State private var firstName = ""
    @State private var lastName = ""

    // Kan grubu artık seçmeli
    @State private var bloodType: String = "A+"

    @State private var birthDate = Date()

    // Adresler: tek adresle başla, isterse "Adres Ekle" ile çoğaltır
    @State private var addresses: [AddressForm] = [
        AddressForm(label: "Ev", addressLine: "", district: "", city: "")
    ]

    @State private var phone = ""
    @State private var showSuccessView = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case firstName, lastName, phone, address
    }

    private var computedAge: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }

    private var canSubmit: Bool {
        guard !firstName.trimmed.isEmpty,
              !lastName.trimmed.isEmpty
        else { return false }

        return addresses.allSatisfy { $0.isValid }
    }

    var body: some View {
        ZStack {
            if showSuccessView {
                RegistrationSuccessView()
                    .transition(.opacity.combined(with: .scale))
            } else {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: DS.Spacing.m) {
                            header

                            DSCard("Kişisel Bilgiler") {
                                VStack(spacing: DS.Spacing.s) {
                                    DSField(title: "Ad", text: $firstName)
                                        .focused($focusedField, equals: .firstName)
                                    DSField(title: "Soyad", text: $lastName)
                                        .focused($focusedField, equals: .lastName)

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

                                    // Kan grubu picker
                                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                                        Text("Kan Grubu")
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.muted)

                                        Picker("Kan Grubu", selection: $bloodType) {
                                            ForEach(["A+","A-","B+","B-","AB+","AB-","0+","0-"], id: \.self) { type in
                                                Text(type).tag(type)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .tint(DS.Colors.primary)
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

                            DSCard("Adres") {
                                VStack(spacing: DS.Spacing.s) {
                                    ForEach($addresses) { $addr in
                                        AddressFormCard(
                                            address: $addr,
                                            canRemove: addresses.count > 1
                                        ) {
                                            addresses.removeAll { $0.id == addr.id }
                                        }
                                    }

                                    Button {
                                        addresses.append(AddressForm(label: "Yeni Adres", addressLine: "", district: "", city: ""))
                                    } label: {
                                        Label("Adres Ekle", systemImage: "plus")
                                    }
                                    .foregroundStyle(DS.Colors.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }

                            DSCard("İletişim (Opsiyonel)") {
                                DSField(title: "Telefon", text: $phone)
                                    .keyboardType(.phonePad)
                                    .focused($focusedField, equals: .phone)
                            }

                            Button {
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

                                // Klavyeyi kapat
                                focusedField = nil

                                // Success view göster
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    showSuccessView = true
                                }

                                // 2-3 saniye sonra ana sayfaya geç
                                Task {
                                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                                    await MainActor.run {
                                        onCompleted()
                                    }
                                }
                            } label: {
                                Text("Kaydı Tamamla")
                            }
                            .buttonStyle(DSPrimaryButtonStyle())
                            .disabled(!canSubmit)
                            .opacity(canSubmit ? 1 : 0.5)

                            Spacer(minLength: DS.Spacing.xl)
                        }
                        .padding(DS.Spacing.l)
                        .onTapGesture {
                            // Boşluğa tıklayınca klavyeyi kapat
                            focusedField = nil
                        }
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
        !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !addressLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !district.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func toModel() -> Address {
        Address(
            id: id,
            label: label.trimmingCharacters(in: .whitespacesAndNewlines),
            addressLine: addressLine.trimmingCharacters(in: .whitespacesAndNewlines),
            district: district.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

// MARK: - Registration Success View
private struct RegistrationSuccessView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            DS.Colors.primary.ignoresSafeArea()
            
            VStack(spacing: DS.Spacing.l) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                Text("Kayıt Tamamlandı!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .opacity(opacity)
                
                Text("Ana sayfaya yönlendiriliyorsunuz...")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.9))
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
