import Combine
import CoreLocation

public typealias IONGLOCService = IONGLOCServicesChecker & IONGLOCAuthorisationHandler & IONGLOCSingleLocationHandler & IONGLOCMonitorLocationHandler

public struct IONGLOCServicesValidator: IONGLOCServicesChecker {
    public init() {}

    public func areLocationServicesEnabled() -> Bool {
        CLLocationManager.locationServicesEnabled()
    }
}

public class IONGLOCManagerWrapper: NSObject, IONGLOCService {
    @Published public var authorisationStatus: IONGLOCAuthorisation
    public var authorisationStatusPublisher: Published<IONGLOCAuthorisation>.Publisher { $authorisationStatus }

    @Published public var currentLocation: IONGLOCPositionModel?
    public var currentLocationPublisher: AnyPublisher<IONGLOCPositionModel, IONGLOCLocationError> {
        $currentLocation
            .dropFirst()    // ignore the first value as it's the one set on the constructor.
            .tryMap { location in
                guard let location else { throw IONGLOCLocationError.locationUnavailable }
                return location
            }
            .mapError { $0 as? IONGLOCLocationError ?? .other($0) }
            .eraseToAnyPublisher()
    }

    private let locationManager: CLLocationManager
    private let servicesChecker: IONGLOCServicesChecker

    public init(locationManager: CLLocationManager = .init(), servicesChecker: IONGLOCServicesChecker = IONGLOCServicesValidator()) {
        self.locationManager = locationManager
        self.servicesChecker = servicesChecker
        self.authorisationStatus = locationManager.currentAuthorisationValue

        super.init()
        locationManager.delegate = self
    }

    public func requestAuthorisation(withType authorisationType: IONGLOCAuthorisationRequestType) {
        authorisationType.requestAuthorization(using: locationManager)
    }

    public func startMonitoringLocation() {
        locationManager.startUpdatingLocation()
    }

    public func stopMonitoringLocation() {
        locationManager.stopUpdatingLocation()
    }

    public func requestSingleLocation() {
        locationManager.requestLocation()
    }

    public func updateConfiguration(_ configuration: IONGLOCConfigurationModel) {
        locationManager.desiredAccuracy = configuration.enableHighAccuracy ? kCLLocationAccuracyBest : kCLLocationAccuracyThreeKilometers
        configuration.minimumUpdateDistanceInMeters.map {
            locationManager.distanceFilter = $0
        }
    }

    public func areLocationServicesEnabled() -> Bool {
        servicesChecker.areLocationServicesEnabled()
    }
}

extension IONGLOCManagerWrapper: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorisationStatus = manager.currentAuthorisationValue
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else {
            currentLocation = nil
            return
        }
        currentLocation = IONGLOCPositionModel.create(from: latestLocation)
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        currentLocation = nil
    }
}
