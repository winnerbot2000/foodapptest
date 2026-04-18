import Foundation
import Combine
import CoreLocation

struct DeviceLocationSnapshot: Equatable {
    let latitude: Double
    let longitude: Double
}

@MainActor
final class CurrentLocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var isRequestingLocation = false
    @Published private(set) var errorMessage: String?

    private let locationManager: CLLocationManager
    private var pendingContinuation: CheckedContinuation<DeviceLocationSnapshot?, Never>?
    private var shouldRequestLocationAfterAuthorization = false

    override init() {
        let locationManager = CLLocationManager()
        self.locationManager = locationManager
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestCurrentLocation() async -> DeviceLocationSnapshot? {
        errorMessage = nil

        if pendingContinuation != nil {
            errorMessage = "A location request is already in progress."
            return nil
        }

        let status = locationManager.authorizationStatus
        authorizationStatus = status

        return await withCheckedContinuation { continuation in
            pendingContinuation = continuation

            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                requestLocationFromManager()
            case .notDetermined:
                shouldRequestLocationAfterAuthorization = true
                locationManager.requestWhenInUseAuthorization()
            case .denied, .restricted:
                errorMessage = "Location access is optional. Enable it in Settings if you want to attach your current location."
                finishRequest(with: nil)
            @unknown default:
                errorMessage = "Current location is unavailable right now."
                finishRequest(with: nil)
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        guard shouldRequestLocationAfterAuthorization else {
            return
        }

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            shouldRequestLocationAfterAuthorization = false
            requestLocationFromManager()
        case .denied, .restricted:
            shouldRequestLocationAfterAuthorization = false
            errorMessage = "Location access was not granted. You can still enter a place manually."
            finishRequest(with: nil)
        case .notDetermined:
            break
        @unknown default:
            shouldRequestLocationAfterAuthorization = false
            errorMessage = "Current location is unavailable right now."
            finishRequest(with: nil)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            errorMessage = "No usable location was returned."
            finishRequest(with: nil)
            return
        }

        finishRequest(
            with: DeviceLocationSnapshot(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        )
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let message: String

        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                message = "Location access was denied. You can still save the entry without it."
            case .locationUnknown:
                message = "The device could not determine a location just now. Please try again."
            default:
                message = "Current location could not be retrieved: \(clError.localizedDescription)"
            }
        } else {
            message = "Current location could not be retrieved: \(error.localizedDescription)"
        }

        errorMessage = message
        finishRequest(with: nil)
    }

    private func requestLocationFromManager() {
        isRequestingLocation = true
        locationManager.requestLocation()
    }

    private func finishRequest(with snapshot: DeviceLocationSnapshot?) {
        isRequestingLocation = false
        shouldRequestLocationAfterAuthorization = false
        pendingContinuation?.resume(returning: snapshot)
        pendingContinuation = nil
    }
}
