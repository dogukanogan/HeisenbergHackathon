//
//  NotificationService.swift
//  HomeScreen
//
//  Created by Auto on 30.01.2026.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private init() {}
    
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
    
    func sendDetectionNotification(soundLabel: String, confidence: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Acil Durum Tespit Edildi"
        content.body = "Tespit edilen ses: \(soundLabel) (Güven: \(Int(confidence * 100))%)"
        content.sound = .defaultCritical
        content.categoryIdentifier = "EMERGENCY_DETECTION"
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Hemen gönder
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
