# 🚨 Emergency Sound Detection System

[![iOS](https://img.shields.io/badge/iOS-17.6+-blue.svg)](https://developer.apple.com/ios/)
[![macOS](https://img.shields.io/badge/macOS-14.0+-blue.svg)](https://developer.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org/)
[![Core ML](https://img.shields.io/badge/Core%20ML-✓-green.svg)](https://developer.apple.com/machine-learning/core-ml/)

A real-time emergency sound detection system that uses Core ML and SoundAnalysis framework to detect critical sounds (fire, scream, collapse, etc.) and automatically sends detection data to a macOS monitoring application via Bonjour.

**Acil durum seslerini gerçek zamanlı olarak algılayan ve tespit verilerini macOS uygulamasına Bonjour ile otomatik olarak gönderen bir sistem.**

---

## 📱 Features / Özellikler

### iOS Application
- ✅ **Real-time Sound Classification** - Core ML model ile gerçek zamanlı ses sınıflandırma
- ✅ **10-Second Listening Period** - 10 saniyelik dinleme süresi ile kararlı tespit
- ✅ **Top 3 Sound Detection** - En yüksek güven seviyesine sahip 3 ses tespiti
- ✅ **90%+ Confidence Threshold** - %90 ve üzeri güven seviyesi ile bildirim
- ✅ **Sticky Detection** - Yüksek güvenli tespitlerin kısa süreliğine kilitlenmesi
- ✅ **User Profile Management** - Kullanıcı profili yönetimi (ad, adres, kan grubu, vb.)
- ✅ **Bonjour Data Transmission** - macOS uygulamasına otomatik veri gönderimi
- ✅ **Emergency Notifications** - Acil durum bildirimleri

### macOS Application
- ✅ **Bonjour Service Discovery** - iOS uygulamasını otomatik keşfetme
- ✅ **Real-time Data Reception** - Gerçek zamanlı veri alma
- ✅ **Detection List View** - Tespit edilen olayların listesi
- ✅ **Detailed View** - Detaylı görünüm (profil + tespit bilgileri)
- ✅ **JSON Export** - JSON verilerini görüntüleme ve kopyalama
- ✅ **Sample Data** - Örnek veriler ile ekran doldurma

---

## 🏗️ Architecture / Mimari

### iOS App Structure
```
HomeScreen/
├── App/                    # App entry point & routing
├── Features/
│   ├── Auth/              # Home view, registration, JSON export
│   └── Settings/          # Settings view
├── Services/
│   ├── SoundClassifierService.swift    # Core ML sound classification
│   ├── BonjourServer.swift             # Bonjour server for data transmission
│   └── NotificationService.swift       # Push notifications
├── Models/
│   └── UserProfile.swift               # User profile data model
├── Storage/
│   └── ProfileStore.swift              # Profile persistence
└── model21.mlmodel                     # Core ML sound classification model
```

### macOS App Structure
```
macApp/
├── Services/
│   ├── BonjourService.swift    # Bonjour client for service discovery
│   └── DataManager.swift       # Data management & storage
├── Views/
│   ├── DetectionListView.swift # List of detections
│   └── DetectionDetailView.swift # Detailed view
└── Models/
    └── UserProfile.swift       # Data models matching iOS format
```

---

## 🛠️ Technologies / Teknolojiler

- **SwiftUI** - Modern UI framework
- **Core ML** - Machine learning model inference
- **SoundAnalysis** - Real-time audio analysis
- **AVAudioEngine** - Audio input processing
- **Bonjour (Network.framework)** - Local network service discovery
- **Combine** - Reactive programming
- **Swift Concurrency** - async/await for asynchronous operations

---

## 📋 Requirements / Gereksinimler

### iOS
- iOS 17.6+
- Xcode 15.0+
- Microphone permission
- Local network permission (for Bonjour)

### macOS
- macOS 14.0+
- Xcode 15.0+
- Local network permission (for Bonjour)

---

## 🚀 Installation / Kurulum

### 1. Clone the repository
```bash
git clone https://github.com/yourusername/emergency-sound-detection.git
cd emergency-sound-detection
```

### 2. iOS App Setup
1. Open `HomeScreen.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run on iOS device or simulator
4. Grant microphone and local network permissions when prompted

### 3. macOS App Setup
1. Open `macApp/macApp.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run on macOS
4. Grant local network permission when prompted

---

## 📖 Usage / Kullanım

### iOS App

1. **First Launch** - İlk açılışta kullanıcı profili oluşturulur (ad, soyad, yaş, kan grubu, adres, telefon)

2. **Start Listening** - Ana ekrandaki büyük butona basarak dinlemeyi başlatın

3. **Detection Process**:
   - Uygulama 10 saniye boyunca ortam seslerini dinler
   - Core ML model gerçek zamanlı olarak sesleri analiz eder
   - En yüksek güven seviyesine sahip 3 ses tespit edilir
   - %90+ güven seviyesi varsa bildirim gönderilir

4. **Alert** - Tespit sonrası "Acil durum algılandı" uyarısı gösterilir

5. **Data Transmission** - Tespit verileri otomatik olarak macOS uygulamasına Bonjour ile gönderilir

### macOS App

1. **Launch** - macOS uygulamasını başlatın

2. **Auto Discovery** - Uygulama otomatik olarak aynı ağdaki iOS uygulamasını keşfeder

3. **View Detections** - Gelen tespitler otomatik olarak listeye eklenir

4. **View Details** - Listeden bir tespit seçerek detaylı bilgileri görüntüleyin:
   - Kullanıcı profili (ad, adres, kan grubu, vb.)
   - Tespit edilen sesler (top 3, güven seviyeleri ile)
   - Ham JSON verisi

---

## 🎯 Sound Detection Model

The app uses a custom Core ML model (`model21.mlmodel`) trained to detect the following sounds:

**Tespit Edilen Sesler:**
- 🔥 `crackling_fire` - Ateş çıtırtısı
- 😱 `scream` - Çığlık
- 💥 `collapse` - Çökme
- 🚨 `siren` - Siren
- 🚗 `car_horn` - Araba kornası
- 💨 `breath` - Nefes
- 😢 `cry` - Ağlama
- 🌊 `sea_waves` - Deniz dalgaları
- ⛈️ `thunderstorm` - Fırtına
- 🌧️ `rain` - Yağmur
- 💧 `water_drops` - Su damlaları
- 🚪 `door_wood_creaks` - Kapı gıcırtısı
- 🚪 `door_wood_knock` - Kapı vurma
- 🌬️ `wind` - Rüzgar
- 🏠 `emptyRoom` - Boş oda
- 🚗 `engine` - Motor
- 💧 `pouring_water` - Su dökme

---

## 🔧 Configuration / Yapılandırma

### iOS - Detection Parameters

In `ListeningViewModule.swift`:
- `evaluationDuration`: 10.0 seconds (listening period)
- `confidenceThreshold`: 0.90 (90% minimum confidence for notifications)
- `lockThreshold`: 0.75 (75% confidence for sticky detection)
- `lockDuration`: 3.0 seconds (sticky detection lock duration)

### Bonjour Service

Service type: `_emergencyapp._tcp`
Service name: `EmergencyApp`

Both apps must be on the same local network for Bonjour to work.

Bonjour'u yerel ağ üzerinden hackathon projesi için kullandık.
Asıl düşüncemiz şu: İlettiğimiz JSON verisi 1KB'dan bile küçük olduğu için,
2G/EDGE gibi düşük bant genişliğine sahip bağlantılarda bile sorunsuz iletilebilir.
Bu sayede hatların dolması veya veri iletim sorunları gibi problemler yaşanmaz.

We used Bonjour over local network for this hackathon project.
Our core idea is this: Since the JSON data we transmit is less than 1KB,
it can be reliably transmitted even over low-bandwidth connections like 2G/EDGE.
This ensures that network congestion or data transmission failures are not an issue.

---

## 📊 Data Format / Veri Formatı

The JSON data sent from iOS to macOS follows this structure:

```json
{
  "id": "UUID",
  "timestamp": "2026-01-30T12:00:00Z",
  "userProfile": {
    "id": "UUID",
    "firstName": "John",
    "lastName": "Doe",
    "age": 30,
    "bloodType": "A+",
    "addresses": [
      {
        "id": "UUID",
        "street": "123 Main St",
        "city": "Istanbul",
        "country": "Turkey"
      }
    ],
    "phoneNumber": "+90 555 123 4567"
  },
  "detections": [
    {
      "id": "UUID",
      "label": "crackling_fire",
      "confidence": 0.95,
      "rank": 1,
      "timestamp": "2026-01-30T12:00:00Z"
    },
    {
      "id": "UUID",
      "label": "scream",
      "confidence": 0.12,
      "rank": 2,
      "timestamp": "2026-01-30T12:00:00Z"
    },
    {
      "id": "UUID",
      "label": "collapse",
      "confidence": 0.08,
      "rank": 3,
      "timestamp": "2026-01-30T12:00:00Z"
    }
  ]
}
```

---

## 🐛 Troubleshooting / Sorun Giderme

### iOS App Issues

**Problem:** No sound detection / Ses tespit edilmiyor
- ✅ Check microphone permission
- ✅ Ensure audio session is active
- ✅ Verify model is loaded correctly
- ✅ Check console logs for buffer processing

**Problem:** Bonjour connection failed / Bonjour bağlantısı başarısız
- ✅ Check `NSBonjourServices` in Info.plist
- ✅ Ensure both devices are on same network
- ✅ Check `NSLocalNetworkUsageDescription` permission

### macOS App Issues

**Problem:** Not receiving data / Veri alınamıyor
- ✅ Check Bonjour service discovery logs
- ✅ Verify network permissions in Info.plist and entitlements
- ✅ Ensure iOS app is running and listening

**Problem:** JSON parse error / JSON parse hatası
- ✅ Check console logs for raw JSON data
- ✅ Verify data models match JSON structure
- ✅ Check for data truncation in network transmission

---

## 📝 License / Lisans

This project is created for educational/hackathon purposes.

Bu proje eğitim/hackathon amaçlı oluşturulmuştur.

---

## 👥 Contributors / Katkıda Bulunanlar

- Doğukan Ogan
- Görkem Çelik
- Oğuz Arda Orhan
- İbrahim Kaan Karaman

---

## 🙏 Acknowledgments / Teşekkürler

- Apple Core ML & SoundAnalysis frameworks
- Create ML for model training
- SwiftUI community

---

## 📞 Contact / İletişim

For questions or issues, please open an issue on GitHub.

Sorularınız veya sorunlarınız için lütfen GitHub'da issue açın.
