//
//  DesignSystem.swift
//  HomeScreen
//
//  Created by Görkem Çelik on 30.01.2026.
//

import SwiftUI

enum DS {
    enum Colors {
        static let background = Color(.systemBackground)
        static let text = Color(.label)
        static let destructive = Color.red
        static let muted = Color(.secondaryLabel)
        static let card = Color(.secondarySystemBackground)
    }

    enum Spacing {
        static let xs: CGFloat = 6
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 24
    }

    enum Radius {
        static let m: CGFloat = 14
        static let l: CGFloat = 20
    }

    enum Typography {
        static let title = Font.system(size: 22, weight: .bold)
        static let body = Font.system(size: 16, weight: .regular)
        static let caption = Font.system(size: 13, weight: .regular)
    }
}
