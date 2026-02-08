//
//  LocationService.swift
//  HomeScreen
//
//  Konum servisi - sürekli konum takibi
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var isAuthorized: Bool = false
    
    private var locationUpdateTimer: Timer?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10 metre değişiklikte güncelle
    }
    
    // İzin iste
    func requestPermission() {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            print("⚠️ Konum izni reddedildi")
        @unknown default:
            break
        }
    }
    
    // Konum güncellemelerini başlat
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("⚠️ Konum izni yok, güncelleme başlatılamıyor")
            return
        }
        
        locationManager.startUpdatingLocation()
        print("📍 Konum güncellemeleri başlatıldı")
        
        // Her 30 saniyede bir güncelle (pil tasarrufu için)
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.locationManager.requestLocation()
        }
    }
    
    // Konum güncellemelerini durdur
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
        print("📍 Konum güncellemeleri durduruldu")
    }
    
    // Son bilinen konumu al
    func getCurrentLocation() -> (latitude: Double, longitude: Double)? {
        guard let location = currentLocation else {
            return nil
        }
        return (latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location
        print("📍 Konum güncellendi: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Konum hatası: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
            startLocationUpdates()
        case .denied, .restricted:
            isAuthorized = false
            stopLocationUpdates()
        case .notDetermined:
            isAuthorized = false
        @unknown default:
            break
        }
    }
}
