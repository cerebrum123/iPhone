import CoreLocation
    
class Bearing: NSObject {
    
    // MARK: - Shared Instance
    static let shared: Bearing = {
        let instance = Bearing()
        return instance
    }()
    
    /**
     Calculate initial compass bearing between two locations
     
     - parameter fromLocation: Source Location
     - parameter toLocation: Destination Location
     
     - returns: bearing (CLLocationDirection)
     */
    func bearingFromLocation(fromLocation: CLLocation, toLocation: CLLocation) -> CLLocationDirection {
        
        var bearing: CLLocationDirection
        
        let fromLat = degreesToRadians(degrees: fromLocation.coordinate.latitude)
        let fromLon = degreesToRadians(degrees: fromLocation.coordinate.longitude)
        let toLat = degreesToRadians(degrees: toLocation.coordinate.latitude)
        let toLon = degreesToRadians(degrees: toLocation.coordinate.longitude)
        
        let y = sin(toLon - fromLon) * cos(toLat)
        let x = cos(fromLat) * sin(toLat) - sin(fromLat) * cos(toLat) * cos(toLon - fromLon)
        bearing = radiansToDegrees( radians: atan2(y, x) ) as CLLocationDirection
        
        bearing = (bearing + 360.0).truncatingRemainder(dividingBy: 360.0)
        return bearing
    }
    
    /**
     Calculate final bearing between two locations
     
     - parameter fromLocation: Source Location
     - parameter toLocation: Destination Location
     
     - returns: bearing (CLLocationDirection)
     */
    func finalBearingFromLocation(fromLocation: CLLocationCoordinate2D, toLocation: CLLocationCoordinate2D) -> CLLocationDirection {
        
        var bearing: CLLocationDirection
        
        let fromLat = degreesToRadians(degrees: fromLocation.latitude)
        let fromLon = degreesToRadians(degrees: fromLocation.longitude)
        let toLat = degreesToRadians(degrees: toLocation.latitude)
        let toLon = degreesToRadians(degrees: toLocation.longitude)
        
        let y = sin(fromLon - toLon) * cos(fromLat)
        let x = cos(toLat) * sin(fromLat) - sin(toLat) * cos(fromLat) * cos(fromLon - toLon)
        bearing = radiansToDegrees( radians: atan2(y, x) ) as CLLocationDirection
        
        bearing = (bearing + 180.0).truncatingRemainder(dividingBy: 360.0)
        
        return bearing
    }
    
    /**
     Calculate angle of elevation between two locations
     
     - parameter fromLocation: Source Location
     - parameter distance: Destination Distance
     - parameter altitude: Destination Altitude
     
     - returns: elevation (Double)
     */
    func elevationFromLocation(fromLocation: CLLocation, toLocation: CLLocation) -> Double {
        
        var elevation: Double
        
        let elevDiff = toLocation.altitude - fromLocation.altitude
        let distance = toLocation.distance(from: fromLocation)
        let elevAngle = atan2(elevDiff, distance)
        
        elevation = radiansToDegrees(radians: elevAngle - distance / 10)
        
        return elevation
        
    }
    
    func degreesToRadians(degrees: Double) -> Double { return degrees * .pi / 180.0 }
    
    func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / .pi }
}
