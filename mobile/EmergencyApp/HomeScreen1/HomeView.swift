
import SwiftUI

struct HomeView: View {
    @StateObject private var flow = EmergencyFlowController()

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            // Tek ana buton (bildirimleri başlatır)
            Button(action: {
                flow.startListening(durationSeconds: 10)
                NotificationService.shared.requestPermission()
                NotificationService.shared.startEmergencyNotifications()
            }) {
                Text("ACİL DURUM")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .background(Color.red)
                    .cornerRadius(28)
                    .padding(.horizontal, 24)
            }
            
            if flow.isListening {
                               Text("Dinleniyor... (10 sn)")
                                   .font(.headline)
                                   .foregroundColor(.gray)
                           }

                           // 🔥 Algılanan olay
                           if let detected = flow.detectedEventType {
                               Text("Algılanan: \(detected)")
                                   .font(.headline)
                                   .foregroundColor(detected == "FIRE" ? .red : .black)
                           }
                       }

            // Sağ altta ayarlar butonu
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        print("Ayarlar açılacak")
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                            .padding(14)
                            .background(Color.gray)
                            .clipShape(Circle())
                    }
                    .padding()
                }
            }
        }
    }


