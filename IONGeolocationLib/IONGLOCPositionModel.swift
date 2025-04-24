import CoreLocation

public struct IONGLOCPositionModel: Equatable {
    private(set) public var altitude: Double
    private(set) public var course: Double
    private(set) public var horizontalAccuracy: Double
    private(set) public var latitude: Double
    private(set) public var longitude: Double
    private(set) public var speed: Double
    private(set) public var timestamp: Double
    private(set) public var verticalAccuracy: Double
    private(set) public var isMock: Bool

    private init(altitude: Double, course: Double, horizontalAccuracy: Double, latitude: Double, longitude: Double, speed: Double, timestamp: Double, verticalAccuracy: Double, isMock: Bool) {
        self.altitude = altitude
        self.course = course
        self.horizontalAccuracy = horizontalAccuracy
        self.latitude = latitude
        self.longitude = longitude
        self.speed = speed
        self.timestamp = timestamp
        self.verticalAccuracy = verticalAccuracy
        self.isMock = isMock
    }
}



public extension IONGLOCPositionModel {

    static func getIsMock(from location: CLLocation) -> Bool {
        var isMock = false
        if #available(iOS 15.0, *) {
            let isLocationSimulated = location.sourceInformation?.isSimulatedBySoftware ?? false
            let isProducedByAccess = location.sourceInformation?.isProducedByAccessory ?? false
                
            let info = CLLocationSourceInformation(softwareSimulationState: isLocationSimulated, andExternalAccessoryState: isProducedByAccess)
                
            if info.isSimulatedBySoftware == true || info.isProducedByAccessory == true{
                isMock = true
            } else {
                isMock = false
            }
        }
        return isMock
    }
    
    static func create(from location: CLLocation) -> IONGLOCPositionModel {
        .init(
            altitude: location.altitude,
            course: location.course,
            horizontalAccuracy: location.horizontalAccuracy,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            speed: location.speed,
            timestamp: location.timestamp.millisecondsSinceUnixEpoch,
            verticalAccuracy: location.verticalAccuracy,
            isMock: getIsMock(from: location)
        )
    }
}

private extension Date {
    var millisecondsSinceUnixEpoch: Double {
        timeIntervalSince1970 * 1000
    }
}
