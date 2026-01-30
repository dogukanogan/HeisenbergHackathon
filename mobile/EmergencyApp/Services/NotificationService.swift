import Foundation
import UserNotifications

final class NotificationService {

    static let shared = NotificationService()

    private init() {}

    private let secondNotificationID = "emergency_second_notification"

    // İzin iste
    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error = error {
                    print("Bildirim izin hatası:", error)
                }
            }
    }

    // Acil durum başlat
    func startEmergencyNotifications() {
        // 1. Bildirim (hemen)
        let firstContent = UNMutableNotificationContent()
        firstContent.title = "Acil Durum"
        firstContent.body = "Durum algılanıyor, lütfen sakin olunuz."
        firstContent.sound = .default

        let firstRequest = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: firstContent,
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: 1,
                repeats: false
            )
        )

        UNUserNotificationCenter.current().add(firstRequest)

        // 2. Bildirim (30 sn sonra)
        let secondContent = UNMutableNotificationContent()
        secondContent.title = "Acil Durum"
        secondContent.body = "Durum algılandı, konumunuza ekipler yönlendiriliyor."
        secondContent.sound = .default

        let secondRequest = UNNotificationRequest(
            identifier: secondNotificationID,
            content: secondContent,
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: 30,
                repeats: false
            )
        )

        UNUserNotificationCenter.current().add(secondRequest)
    }

    // İptal et
    func cancelEmergency() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [secondNotificationID]
            )
    }
}
