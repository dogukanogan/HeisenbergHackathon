//
//  macAppApp.swift
//  macApp
//
//  Created by Doğukan Ogan on 31.01.2026.
//

import SwiftUI

@main
struct macAppApp: App {
    var body: some Scene {
        WindowGroup {
            DetectionListView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1000, height: 700)
    }
}
