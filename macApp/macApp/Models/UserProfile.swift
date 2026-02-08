import Foundation

struct LocationData: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    
    var isValid: Bool {
        // Geçersiz koordinatları kontrol et (0,0 veya çok büyük değerler)
        return latitude != 0 && longitude != 0 &&
               latitude >= -90 && latitude <= 90 &&
               longitude >= -180 && longitude <= 180
    }
}

struct Address: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var label: String
    var addressLine: String
    var district: String
    var city: String
    
    // iOS'tan gelen JSON'da id yok, decode sırasında otomatik oluştur
    enum CodingKeys: String, CodingKey {
        case label, addressLine, district, city
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try container.decode(String.self, forKey: .label)
        addressLine = try container.decode(String.self, forKey: .addressLine)
        district = try container.decode(String.self, forKey: .district)
        city = try container.decode(String.self, forKey: .city)
        id = UUID() // Her decode'da yeni ID oluştur
    }
    
    init(id: UUID = UUID(), label: String, addressLine: String, district: String, city: String) {
        self.id = id
        self.label = label
        self.addressLine = addressLine
        self.district = district
        self.city = city
    }
}

struct UserProfile: Codable, Equatable {
    var id: UUID = UUID()
    var firstName: String
    var lastName: String
    var birthDate: Date
    var bloodType: String
    var addresses: [Address]
    var phone: String?
    var createdAt: Date = Date()
    
    var fullName: String { "\(firstName) \(lastName)" }
    
    var age: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }
    
    // iOS'tan gelen JSON'da id ve createdAt yok olabilir, decode sırasında handle et
    enum CodingKeys: String, CodingKey {
        case firstName, lastName, birthDate, bloodType, addresses, phone, createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        birthDate = try container.decode(Date.self, forKey: .birthDate)
        bloodType = try container.decode(String.self, forKey: .bloodType)
        addresses = try container.decode([Address].self, forKey: .addresses)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
        id = UUID() // Her decode'da yeni ID oluştur
    }
    
    init(id: UUID = UUID(), firstName: String, lastName: String, birthDate: Date, bloodType: String, addresses: [Address], phone: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.birthDate = birthDate
        self.bloodType = bloodType
        self.addresses = addresses
        self.phone = phone
        self.createdAt = createdAt
    }
}

struct Detection: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    let sound: String
    let confidence: Double
    let rank: Int
    
    // iOS'tan gelen JSON'da id yok, decode sırasında otomatik oluştur
    enum CodingKeys: String, CodingKey {
        case sound, confidence, rank
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sound = try container.decode(String.self, forKey: .sound)
        confidence = try container.decode(Double.self, forKey: .confidence)
        rank = try container.decode(Int.self, forKey: .rank)
        id = UUID() // Her decode'da yeni ID oluştur
    }
    
    init(id: UUID = UUID(), sound: String, confidence: Double, rank: Int) {
        self.id = id
        self.sound = sound
        self.confidence = confidence
        self.rank = rank
    }
}

struct ExportData: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    let detections: [Detection]
    let profile: UserProfile
    let timestamp: Date
    let location: LocationData?
    
    // iOS'tan gelen JSON'da id yok, decode sırasında otomatik oluştur
    enum CodingKeys: String, CodingKey {
        case detections, profile, timestamp, location
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        detections = try container.decode([Detection].self, forKey: .detections)
        profile = try container.decode(UserProfile.self, forKey: .profile)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        location = try container.decodeIfPresent(LocationData.self, forKey: .location)
        id = UUID() // Her decode'da yeni ID oluştur
    }
    
    init(id: UUID = UUID(), detections: [Detection], profile: UserProfile, timestamp: Date, location: LocationData? = nil) {
        self.id = id
        self.detections = detections
        self.profile = profile
        self.timestamp = timestamp
        self.location = location
    }
}
