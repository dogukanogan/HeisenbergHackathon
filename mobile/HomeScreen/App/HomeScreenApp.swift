//
//  HomeScreenApp.swift
//  HomeScreen
//
//  Created by Görkem Çelik on 30.01.2026.
//

import SwiftUI

@main
struct HomeScreenApp: App {
    @StateObject private var router = AppRouter()
    
    init() {
        // Uygulama başladığında Bonjour server'ı başlat
        BonjourServer.shared.start()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
        }
    }
}
