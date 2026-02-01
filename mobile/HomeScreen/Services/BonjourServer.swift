import Foundation
import Network

final class BonjourServer {
    static let shared = BonjourServer()
    
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private let serviceType = "_emergencyapp._tcp"
    private let serviceName = "EmergencyApp"
    private var pendingJSON: String? // Bağlantı kurulana kadar bekleyen JSON
    
    private init() {}
    
    func start() {
        // Eğer zaten çalışıyorsa tekrar başlatma
        if listener != nil {
            print("⚠️ Bonjour server zaten çalışıyor")
            return
        }
        
        // Peer-to-peer yerine normal TCP kullan (aynı ağda oldukları için)
        let parameters = NWParameters.tcp
        
        do {
            listener = try NWListener(using: parameters, on: 0)
            
            let service = NWListener.Service(name: serviceName, type: serviceType)
            listener?.service = service
            print("📡 Bonjour servisi ayarlandı: \(serviceName) (\(serviceType))")
            
            listener?.newConnectionHandler = { [weak self] connection in
                print("🔗 Yeni bağlantı isteği geldi")
                self?.handleConnection(connection)
            }
            
            listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    if let port = self?.listener?.port {
                        print("✅ Bonjour server hazır (port: \(port))")
                    } else {
                        print("✅ Bonjour server hazır")
                    }
                case .waiting(let error):
                    print("⏳ Bonjour server bekleniyor: \(error.localizedDescription)")
                case .failed(let error):
                    print("❌ Bonjour server hatası: \(error.localizedDescription)")
                case .cancelled:
                    print("🚫 Bonjour server iptal edildi")
                default:
                    print("📊 Bonjour server durumu: \(state)")
                    break
                }
            }
            
            listener?.start(queue: .main)
            print("✅ Bonjour server başlatıldı")
        } catch {
            print("❌ Bonjour server başlatılamadı: \(error.localizedDescription)")
        }
    }
    
    func stop() {
        listener?.cancel()
        connections.forEach { $0.cancel() }
        connections.removeAll()
        listener = nil
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connections.append(connection)
        print("🔗 Yeni bağlantı geldi, toplam: \(connections.count)")
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("✅ macOS uygulaması bağlandı (toplam: \(self?.connections.count ?? 0))")
                // Bağlantı kurulduğunda bekleyen JSON'u gönder
                if let pending = self?.pendingJSON {
                    print("📤 Bekleyen JSON gönderiliyor...")
                    self?.sendJSON(pending)
                    self?.pendingJSON = nil
                }
            case .waiting(let error):
                print("⏳ Bağlantı bekleniyor: \(error.localizedDescription)")
            case .failed(let error):
                print("❌ Bağlantı hatası: \(error.localizedDescription)")
                if let index = self?.connections.firstIndex(where: { $0 === connection }) {
                    self?.connections.remove(at: index)
                    print("🔌 Bağlantı kaldırıldı, kalan: \(self?.connections.count ?? 0)")
                }
            case .cancelled:
                print("🚫 Bağlantı iptal edildi")
                if let index = self?.connections.firstIndex(where: { $0 === connection }) {
                    self?.connections.remove(at: index)
                    print("🔌 Bağlantı kaldırıldı, kalan: \(self?.connections.count ?? 0)")
                }
            default:
                print("📊 Bağlantı durumu: \(state)")
                break
            }
        }
        
        connection.start(queue: .main)
        print("🚀 Bağlantı başlatıldı")
    }
    
    func sendJSON(_ jsonData: String) {
        guard let data = jsonData.data(using: .utf8) else {
            print("❌ JSON data'ya çevrilemedi")
            return
        }
        
        print("📤 JSON gönderme denemesi: \(connections.count) bağlantı var")
        
        // Hazır bağlantı var mı kontrol et
        let readyConnections = connections.filter { $0.state == .ready }
        
        if readyConnections.isEmpty {
            print("⚠️ Henüz hazır bağlantı yok, JSON bekletiliyor...")
            pendingJSON = jsonData
            return
        }
        
        // Tüm hazır bağlantılara gönder
        var sentCount = 0
        for connection in readyConnections {
            // Uzunluk ve veriyi birleştir, tek seferde gönder
            var length = UInt32(data.count).bigEndian
            let lengthData = Data(bytes: &length, count: 4)
            var completeData = lengthData
            completeData.append(data)
            
            print("📤 Gönderilecek toplam veri: \(completeData.count) bytes (uzunluk: 4 + JSON: \(data.count))")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 JSON string uzunluğu: \(jsonString.count) karakter")
                print("📄 JSON string (tam): \(jsonString)")
            }
            
            // Tek seferde gönder
            connection.send(content: completeData, contentContext: .defaultMessage, isComplete: true, completion: .contentProcessed { error in
                if let error = error {
                    print("❌ JSON gönderme hatası: \(error.localizedDescription)")
                } else {
                    print("✅ JSON macOS'a gönderildi: \(completeData.count) bytes (uzunluk + veri)")
                }
            })
            sentCount += 1
        }
        
        print("✅ \(sentCount) bağlantıya JSON gönderildi")
    }
}
