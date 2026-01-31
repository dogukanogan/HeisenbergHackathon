//
//  JSONExportView.swift
//  HomeScreen
//
//  Created by Auto on 30.01.2026.
//

import SwiftUI

struct JSONExportView: View {
    let jsonData: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("JSON Verisi")
                        .font(DS.Typography.section)
                        .foregroundStyle(DS.Colors.muted)
                        .padding(.horizontal, DS.Spacing.l)
                    
                    Text(jsonData)
                        .font(.system(.caption, design: .monospaced))
                        .padding(DS.Spacing.m)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DS.Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                                .stroke(DS.Colors.border, lineWidth: 1)
                        )
                        .padding(.horizontal, DS.Spacing.l)
                    
                    Button {
                        UIPasteboard.general.string = jsonData
                    } label: {
                        Label("JSON'u Kopyala", systemImage: "doc.on.doc")
                            .font(DS.Typography.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(DS.Colors.primary)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
                    }
                    .padding(.horizontal, DS.Spacing.l)
                }
                .padding(.vertical, DS.Spacing.l)
            }
            .background(DS.Colors.background)
            .navigationTitle("Tespit Detayları")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}
