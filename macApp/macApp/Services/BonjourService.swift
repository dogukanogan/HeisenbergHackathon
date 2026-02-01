import Foundation
import Network
import Combine

final class BonjourService: ObservableObject {
    @Published var isConnected = false
    @Published var connectionStatus: String = "iOS uygulaması aranıyor..."
    
    private var browser: NWBrowser?
    private var connection: NWConnection?
    private let serviceType = "_emergencyapp._tcp"
    private let serviceDomain = "local."
    private let queue = DispatchQueue(label: "com.bonjour.service")
    
    var onDataReceived: ((Data) -> Void)?
    
    func startBrowsing() {
        // Önce mevcut browser'ı durdur
        browser?.cancel()
        browser = nil
        
        // Peer-to-peer yerine normal TCP kullan (aynı ağda oldukları için)
        let parameters = NWParameters.tcp
        
        let descriptor = NWBrowser.Descriptor.bonjour(type: serviceType, domain: serviceDomain)
        browser = NWBrowser(for: descriptor, using: parameters)
        
        browser?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch state {
                case .ready:
                    print("✅ Browser hazır, iOS uygulaması aranıyor...")
                    self.connectionStatus = "iOS uygulaması aranıyor..."
                case .failed(let error):
                    print("❌ Browser hatası: \(error.localizedDescription)")
                    self.connectionStatus = "Hata: \(error.localizedDescription)"
                case .waiting(let error):
                    print("⏳ Browser bekleniyor: \(error.localizedDescription)")
                    self.connectionStatus = "Bağlanıyor..."
                default:
                    print("📊 Browser durumu: \(state)")
                    break
                }
            }
        }
        
        browser?.browseResultsChangedHandler = { [weak self] results, changes in
            print("🔍 Browse sonuçları değişti: \(results.count) sonuç, \(changes.count) değişiklik")
            
            // Değişiklikleri logla
            for change in changes {
                switch change {
                case .added:
                    print("➕ Servis eklendi")
                case .removed:
                    print("➖ Servis kaldırıldı")
                case .changed:
                    print("🔄 Servis değişti")
                @unknown default:
                    print("❓ Bilinmeyen değişiklik")
                }
            }
            
            for result in results {
                print("🔍 Endpoint bulundu: \(result.endpoint)")
                if case .service(let name, let type, let domain, _) = result.endpoint {
                    print("🔍 iOS uygulaması bulundu: \(name) (type: \(type), domain: \(domain))")
                    Task { @MainActor [weak self] in
                        await self?.connect(to: result.endpoint)
                    }
                } else {
                    print("⚠️ Beklenmeyen endpoint tipi: \(result.endpoint)")
                }
            }
            
            if results.isEmpty {
                print("⚠️ Henüz servis bulunamadı")
            }
        }
        
        browser?.start(queue: queue)
        print("✅ Bonjour browser başlatıldı (type: \(serviceType), domain: \(serviceDomain))")
    }
    
    func stopBrowsing() {
        browser?.cancel()
        connection?.cancel()
        browser = nil
        connection = nil
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = false
            self?.connectionStatus = "Bağlantı kesildi"
        }
    }
    
    @MainActor
    private func connect(to endpoint: NWEndpoint) async {
        // Peer-to-peer yerine normal TCP kullan (aynı ağda oldukları için)
        let parameters = NWParameters.tcp
        
        connection = NWConnection(to: endpoint, using: parameters)
        print("🔗 Bağlantı oluşturuldu, başlatılıyor...")
        
        connection?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch state {
                case .ready:
                    print("✅ iOS uygulamasına bağlandı!")
                    self.isConnected = true
                    self.connectionStatus = "iOS uygulamasına bağlandı"
                    self.receiveData()
                case .waiting(let error):
                    print("⏳ Bağlantı bekleniyor: \(error.localizedDescription)")
                    self.connectionStatus = "Bağlanıyor..."
                case .failed(let error):
                    print("❌ Bağlantı hatası: \(error.localizedDescription)")
                    self.isConnected = false
                    self.connectionStatus = "Bağlantı hatası: \(error.localizedDescription)"
                case .cancelled:
                    print("🚫 Bağlantı iptal edildi")
                    self.isConnected = false
                    self.connectionStatus = "Bağlantı kesildi"
                default:
                    print("📊 Bağlantı durumu: \(state)")
                    break
                }
            }
        }
        
        connection?.start(queue: queue)
        print("🚀 Bağlantı başlatıldı")
    }
    
    private var expectedLength: Int? = nil
    private var receivedData = Data()
    
    private func receiveData() {
        guard let connection = connection, connection.state == .ready else {
            print("⚠️ Bağlantı hazır değil, dinleme durduruldu")
            return
        }
        
        // Önce uzunluk bilgisini al (4 byte)
        if expectedLength == nil {
            connection.receive(minimumIncompleteLength: 4, maximumLength: 65536) { [weak self] data, _, isComplete, error in
                guard let self = self else { return }
                
                // Bağlantı durumunu kontrol et
                guard self.connection?.state == .ready else {
                    print("⚠️ Bağlantı hazır değil")
                    return
                }
                
                if let error = error {
                    // Operation canceled hatası genellikle bağlantı kapanırken olur, normal
                    if (error as NSError).code != 89 { // 89 = Operation canceled
                        print("❌ Veri alma hatası: \(error.localizedDescription)")
                    }
                    return
                }
                
                if let data = data, data.count >= 4 {
                    // İlk 4 byte uzunluk
                    let lengthData = data.prefix(4)
                    let length = UInt32(bigEndian: lengthData.withUnsafeBytes { $0.load(as: UInt32.self) })
                    self.expectedLength = Int(length)
                    
                    // Kalan veriyi al (4 byte'tan sonrası)
                    let jsonData = data.dropFirst(4)
                    self.receivedData = Data(jsonData)
                    
                    print("📏 Beklenen veri uzunluğu: \(length) bytes")
                    print("📦 İlk pakette gelen JSON: \(self.receivedData.count) bytes")
                    
                    // Eğer tüm veri geldiyse direkt işle, değilse devam et
                    if let expected = self.expectedLength, self.receivedData.count >= expected {
                        // Tüm veri geldi
                        let completeData = self.receivedData.prefix(expected)
                        print("✅ Tüm veri alındı: \(completeData.count) bytes")
                        DispatchQueue.main.async {
                            self.onDataReceived?(Data(completeData))
                        }
                        self.expectedLength = nil
                        self.receivedData = Data()
                        // Tekrar dinlemeye başla
                        self.receiveData()
                    } else {
                        // Daha fazla veri bekle
                        self.receiveData()
                    }
                } else if data != nil && data!.count > 0 {
                    // 4 byte'tan az veri geldi, tekrar bekle
                    print("⚠️ Yetersiz veri: \(data!.count) bytes, 4 byte bekleniyor")
                    self.receiveData()
                } else {
                    // Veri yok, tekrar dene
                    self.receiveData()
                }
            }
        } else {
            // Veriyi al
            let remaining = expectedLength! - receivedData.count
            connection.receive(minimumIncompleteLength: 1, maximumLength: remaining) { [weak self] data, _, isComplete, error in
                guard let self = self else { return }
                
                // Bağlantı durumunu kontrol et
                guard self.connection?.state == .ready else {
                    print("⚠️ Bağlantı hazır değil")
                    self.expectedLength = nil
                    self.receivedData = Data()
                    return
                }
                
                if let error = error {
                    // Operation canceled hatası genellikle bağlantı kapanırken olur, normal
                    if (error as NSError).code != 89 { // 89 = Operation canceled
                        print("❌ Veri alma hatası: \(error.localizedDescription)")
                    }
                    self.expectedLength = nil
                    self.receivedData = Data()
                    return
                }
                
                if let data = data, !data.isEmpty {
                    self.receivedData.append(data)
                    print("📦 Veri parçası alındı: \(data.count) bytes (toplam: \(self.receivedData.count)/\(self.expectedLength ?? 0))")
                    
                    // Tüm veri geldi mi?
                    if let expected = self.expectedLength, self.receivedData.count >= expected {
                        // Sadece beklenen kadarını al (fazla varsa kes)
                        let jsonData = self.receivedData.prefix(expected)
                        print("✅ Tüm veri alındı: \(jsonData.count) bytes")
                        DispatchQueue.main.async {
                            self.onDataReceived?(Data(jsonData))
                        }
                        // Sıfırla ve tekrar dinlemeye başla
                        self.expectedLength = nil
                        self.receivedData = Data()
                        self.receiveData()
                    } else {
                        // Daha fazla veri bekle
                        self.receiveData()
                    }
                } else {
                    // Veri yok, tekrar dene
                    self.receiveData()
                }
            }
        }
    }
    
    func sendData(_ data: Data) {
        connection?.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("❌ Send error: \(error.localizedDescription)")
            } else {
                print("✅ Veri gönderildi")
            }
        })
    }
}
