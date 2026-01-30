//
//  DesignSystem.swift
//  HomeScreen
//
//  Created by Görkem Çelik on 30.01.2026.
//

import SwiftUI

enum DS {
    enum Colors {
        static let background = Color(.systemGroupedBackground)
        static let card = Color(.secondarySystemGroupedBackground)
        static let text = Color(.label)
        static let muted = Color(.secondaryLabel)

        // Tema
        static let primary = Color.red
        static let primarySoft = Color.red.opacity(0.12)
        static let border = Color.black.opacity(0.08)
    }

    enum Spacing {
        static let xs: CGFloat = 6
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let m: CGFloat = 14
        static let l: CGFloat = 20
        static let xl: CGFloat = 28
    }

    enum Shadow {
        static let soft = (color: Color.black.opacity(0.08), radius: CGFloat(14), y: CGFloat(6))
    }

    enum Typography {
        static let title = Font.system(size: 26, weight: .bold)
        static let section = Font.system(size: 15, weight: .semibold)
        static let body = Font.system(size: 16, weight: .regular)
        static let caption = Font.system(size: 13, weight: .regular)
    }
}

// MARK: - Reusable UI helpers
struct DSCard<Content: View>: View {
    let title: String?
    @ViewBuilder var content: Content

    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            if let title {
                Text(title)
                    .font(DS.Typography.section)
                    .foregroundStyle(DS.Colors.muted)
            }

            content
        }
        .padding(DS.Spacing.m)
        .background(DS.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
        .shadow(color: DS.Shadow.soft.color, radius: DS.Shadow.soft.radius, y: DS.Shadow.soft.y)
    }
}

struct DSPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DS.Typography.body.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(DS.Colors.primary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
    }
}
