//
//  FirstRunWelcomeView.swift
//  HomeScreen
//
//  Created by Görkem Çelik on 30.01.2026.
//

import SwiftUI

struct FirstRunWelcomeView: View {
    let onRegister: () -> Void
    let onLogin: () -> Void

    var body: some View {
        ZStack {
            DS.Colors.primary.ignoresSafeArea()

            VStack(spacing: DS.Spacing.l) {
                Spacer()

                VStack(spacing: DS.Spacing.s) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Hoş geldiniz")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Acil Durum Uygulaması")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }

                Spacer()

                VStack(spacing: DS.Spacing.s) {
                    Button {
                        onRegister()
                    } label: {
                        Text("Kayıt Ol")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(DS.Colors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
                    }

                    Button {
                        onLogin()
                    } label: {
                        Text("Giriş Yap")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.20))
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, DS.Spacing.l)
                .padding(.bottom, DS.Spacing.xl)
            }
        }
    }
}
