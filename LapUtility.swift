import Foundation
import UIKit
import CoreMotion
import CoreLocation
import CoreGPX

class LapUtility: NSObject {
    
    // MARK: - Shared Instance
    static let shared: LapUtility = {
        let instance = LapUtility()
        return instance
    }()
    
    var currentLapNumber:Int = 1
    var isLapStarted:Bool = false
    let motionManager:CMMotionManager = CMMotionManager()
    var previousLocation:CLLocation? = nil
    var shouldDisableMotion:Bool = false
    var lastLapTime:Date? = Date()
    var currentLocationObj:CLLocation? = nil
    
    /**
     This function will be called when there is any location change. It will check details of current lap/session
     @param: latitude an instance of String,longitude an instance of String,currentLocation an instance of CLLocation
     @return: (Bool,Bool) in the form of tuple
     */    
    func checkTrackConfigurationWithCurrentLocation(currentLocation:CLLocation, selectedTrack: Track?) -> (Bool,Bool,Int,Date) {
        
        var responseResult = (false,false,1,currentLocation.timestamp)
        if self.previousLocation?.coordinate.latitude != nil {
            if currentLocation.timestamp < (self.previousLocation?.timestamp)! {
                return responseResult
            }
        }
        self.currentLocationObj = currentLocation
        
        let isIntersectingBool:(Bool,Double,Double,Double,Date?) = self.checkForIntersection(currentLocation: currentLocation,isForEndLocation: self.isLapStarted, selectedTrack: selectedTrack)
        
        if isIntersectingBool.0 == false {
            self.previousLocation = currentLocation
            return responseResult
        }
        
        if isIntersectingBool.0 == true {
            if self.isLapStarted == false {
                responseResult.3 = isIntersectingBool.4!
                responseResult.0 = true
                self.isLapStarted = true
            } else {
                //Additional check if lat long is called twice
                let difference = currentLocation.timestamp.timeIntervalSince(self.lastLapTime!)
                if difference > 1 {
                    self.lastLapTime = currentLocation.timestamp
                }else{
                    self.previousLocation = currentLocation
                    return responseResult
                }
                responseResult.3 = isIntersectingBool.4!
                self.lastLapTime = currentLocation.timestamp
                responseResult.1 = true
                self.currentLapNumber += 1
                responseResult.2 = self.currentLapNumber
            }
        }
        self.previousLocation = currentLocation
        return responseResult
    }
    
    func checkForIntersection(currentLocation:CLLocation,isForEndLocation:Bool, selectedTrack: Track?) -> (Bool,Double,Double,Double,Date?){
        // is intersected, time lapsed before, timelapsed after, distance covered,date of intersection
        if self.previousLocation?.coordinate.latitude == nil {
            return (false,0,0,0,nil)
        }
        let x1:CGFloat = CGFloat(currentLocation.coordinate.latitude)
        let y1:CGFloat = CGFloat(currentLocation.coordinate.longitude)
        let x2:CGFloat = CGFloat((self.previousLocation?.coordinate.latitude)!)
        let y2:CGFloat = CGFloat((self.previousLocation?.coordinate.longitude)!)
        
        var x3:CGFloat
        var y3:CGFloat
        var x4:CGFloat
        var y4:CGFloat
        
        if selectedTrack?.trackType == 0 {
            //Point 3
            x3 = selectedTrack?.finishLeftLat?.cgFloatValue() ?? 0.0//31.380290
            y3 = selectedTrack?.finishLeftLong?.cgFloatValue() ?? 0.0//76.338156
            //Point 4
            x4 = selectedTrack?.finishRightLat?.cgFloatValue() ?? 0.0//31.380283
            y4 = selectedTrack?.finishRightLong?.cgFloatValue() ?? 0.0//76.338053
        }else{
            if !isForEndLocation {
                //Point 3
                 x3 = selectedTrack?.startLeftLat?.cgFloatValue() ?? 0.0
                 y3 = selectedTrack?.startLeftLong?.cgFloatValue() ?? 0.0
                //Point 4
                 x4 = selectedTrack?.startRightLat?.cgFloatValue() ?? 0.0
                 y4 = selectedTrack?.startRightLong?.cgFloatValue() ?? 0.0
            }else{
                //Point 3
                 x3 = selectedTrack?.finishLeftLat?.cgFloatValue() ?? 0.0
                 y3 = selectedTrack?.finishLeftLong?.cgFloatValue() ?? 0.0
                //Point 4
                 x4 = selectedTrack?.finishRightLat?.cgFloatValue() ?? 0.0
                 y4 = selectedTrack?.finishRightLong?.cgFloatValue() ?? 0.0
            }
        }
        
        let ta:CGFloat = (((y3-y4)*(x1-x3))+((x4-x3)*(y1-y3)))/(((x4-x3)*(y1-y2))-((x1-x2)*(y4-y3)))
        let tb:CGFloat = (((y1-y2)*(x1-x3))+((x2-x1)*(y1-y3)))/(((x4-x3)*(y1-y2))-((x1-x2)*(y4-y3)))
        //print(ta, "  ", tb)
        if ta.isNaN || tb.isNaN || ta.isInfinite || tb.isInfinite {
            return (false,0,0,0,nil)
        }
        if ta >= 0 && ta <= 1 && tb >= 0 && tb <= 1 {
            
            //Get first slope current location
            let m1 = (y2-y1)/(x2-x1)
            let c1 = y2 - (m1*x2)
            //Get second slope current object start begin/end and finsh begin/end location
            let m2 = (y4-y3)/(x4-x3)
            let c2 = y4 - (m2*x4)
            var intersectionPointX:CGFloat = (c2 - c1)/(m1-m2)
            var intersectionPointY:CGFloat = ((m1*(c2 - c1))/(m1-m2))+c1
            let getIntersectionPoint = self.getIntersectionPoint(currentLocation: currentLocation, isForEndLocation: isForEndLocation, selectedTrack: selectedTrack)
            if getIntersectionPoint.2 == true {
                intersectionPointX = CGFloat(getIntersectionPoint.0)
                intersectionPointY = CGFloat(getIntersectionPoint.1)
            }
            
            let distanceAfterIntersection:Double = self.calculateDistanceBetweenTwoLocationWithSourceLat1(sourceLatitude: Double(x1), sourceLongitude: Double(y1), destinationLatitude: Double(intersectionPointX), destinationLongitude: Double(intersectionPointY))
            let previousDistance:Double = self.calculateDistanceBetweenTwoLocationWithSourceLat1(sourceLatitude: Double(intersectionPointX), sourceLongitude: Double(intersectionPointY), destinationLatitude: Double(x2), destinationLongitude: Double(y2))
            let speed:Double
            speed = ((currentLocation.speed)+(self.previousLocation?.speed)!)/2
            let timeLapsed = (distanceAfterIntersection/speed)
            let timeLapsedBeforePointIntersection = (previousDistance/speed)
            let date:Date = ((self.previousLocation?.timestamp)!.addingTimeInterval(timeLapsedBeforePointIntersection))
            return (true,timeLapsedBeforePointIntersection*1000,timeLapsed*1000,distanceAfterIntersection,date)
        } else {
            return (false,0,0,0,nil)
        }
    }
    
    func getIntersectionPoint(currentLocation:CLLocation,isForEndLocation:Bool, selectedTrack: Track?) -> (Double,Double,Bool){
        
        let x1:CGFloat = CGFloat(currentLocation.coordinate.latitude)
        let y1:CGFloat = CGFloat(currentLocation.coordinate.longitude)
        let x2:CGFloat = CGFloat((self.previousLocation?.coordinate.latitude)!)
        let y2:CGFloat = CGFloat((self.previousLocation?.coordinate.longitude)!)
        var x3:CGFloat
        var y3:CGFloat
        var x4:CGFloat
        var y4:CGFloat
        
        if selectedTrack?.trackType == 0 {
            //Point 3
            x3 = selectedTrack?.finishLeftLat?.cgFloatValue() ?? 0.0//31.380290
            y3 = selectedTrack?.finishLeftLong?.cgFloatValue() ?? 0.0//76.338156
            //Point 4
            x4 = selectedTrack?.finishRightLat?.cgFloatValue() ?? 0.0//31.380283
            y4 = selectedTrack?.finishRightLong?.cgFloatValue() ?? 0.0//76.338053
        }else{
            if !isForEndLocation {
                //Point 3
                 x3 = selectedTrack?.startLeftLat?.cgFloatValue() ?? 0.0
                 y3 = selectedTrack?.startLeftLong?.cgFloatValue() ?? 0.0
                //Point 4
                 x4 = selectedTrack?.startRightLat?.cgFloatValue() ?? 0.0
                 y4 = selectedTrack?.startRightLong?.cgFloatValue() ?? 0.0
            }else{
                //Point 3
                 x3 = selectedTrack?.finishLeftLat?.cgFloatValue() ?? 0.0
                 y3 = selectedTrack?.finishLeftLong?.cgFloatValue() ?? 0.0
                //Point 4
                 x4 = selectedTrack?.finishRightLat?.cgFloatValue() ?? 0.0
                 y4 = selectedTrack?.finishRightLong?.cgFloatValue() ?? 0.0
            }
        }
        
        let path1Start = Vector3D.sharedObject.toVector(latitude: Double(x2), longitude: Double(y2))
        let path1End = Vector3D.sharedObject.toVector(latitude: Double(x1), longitude: Double(y1))
        let path2Start = Vector3D.sharedObject.toVector(latitude: Double(x3), longitude: Double(y3))
        let path2End = Vector3D.sharedObject.toVector(latitude: Double(x4), longitude: Double(y4))
        
        
        let cc1:Vector3D = path1Start.crossProductVectorVector(vector: path1End)
        let cc2:Vector3D = path2Start.crossProductVectorVector(vector: path2End)
        
        // there are two (antipodal) candidate intersection points; we have to choose which to return
        let ii1:Vector3D = cc1.crossProductVectorVector(vector: cc2)
        let ii2:Vector3D = cc2.crossProductVectorVector(vector: cc1)
        
        // selection of intersection point depends on how paths are defined (bearings or endpoints)
        let mid:Vector3D = path1Start.addVectors(vector: path2Start).addVectors(vector: path1End).addVectors(vector: path2End)
        let intersection:(Double,Double) = (mid.dot(vector: ii1) > 0 ? ii1 : ii2).toLatLong();
        
        if intersection.0 <= 0 && intersection.1 <= 0 {
            return (0,0,false)
        }
        else{
            return (intersection.0,intersection.1,true)
        }
    }
    
    /**
     Enable gyroscope and accelerometer if the drive has started its lap/session.
     */
    func enableMotion() {
        NotificationCenter.default.addObserver(self, selector: #selector(stopGettingMotionUpdatesNotification(notification:)), name: NSNotification.Name.init("stopGettingMotionUpdatesNotification"), object: nil)
        
        if self.motionManager.isDeviceMotionAvailable == true {
            motionManager.deviceMotionUpdateInterval = 0.5
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { (deviceMotion:CMDeviceMotion?, motionError:Error?) in
                
                if self.shouldDisableMotion == true{
                    DispatchQueue.main.async {
                        self.motionManager.stopDeviceMotionUpdates()
                        self.motionManager.stopAccelerometerUpdates()
                    }
                    return
                }
                if motionError == nil{
                    let acceleration:CMAcceleration? = (deviceMotion?.userAcceleration)
                    if let accel = acceleration{
                        _ = String(format: "%0.2f", accel.x)
                        _ = String(format: "%0.2f", accel.x)
                        _ = String(format: "%0.2f", accel.x)
                    }
                    
                    if let attitude:CMAttitude = deviceMotion?.attitude{
                        _ = Double((180/Double.pi)*attitude.pitch)
                        _ = Double((180/Double.pi)*attitude.roll)
                        _ = Double((180/Double.pi)*attitude.yaw)
                    }
                }
            }
        } else {
            print("Motion Sensor not enabled")
        }
    }
    
    /**
     Check if bearing angle is in accordance with selected track configuration
     @param: Current location an instance of CLLocation
     @return: Bool if they are in sync
     */
    func checkBearingAngleWithLocation(location:CLLocation) -> Bool{

        let bearingAngleFromTrackObj:CGFloat
        if self.isLapStarted == true {
            bearingAngleFromTrackObj = CGFloat(0.0)//CGFloat((self.currentTrackObj?.finishBearing)!)
        } else {
            bearingAngleFromTrackObj = CGFloat(0.0)//CGFloat((self.currentTrackObj?.startBearing)!)
        }
        let locationCourse : CGFloat
        locationCourse = CGFloat(location.course)
        var contains = locationCourse-90...locationCourse+90 ~= bearingAngleFromTrackObj
        if contains == false {
            if locationCourse-90 < 0 {
                let bearingAngle = 360 + (locationCourse-90)
                contains = bearingAngle...359 ~= bearingAngleFromTrackObj
            }

            if contains == false {
                if locationCourse+90 > 360 {
                    let bearingAngle = (locationCourse+90) - 360
                    contains = 0...bearingAngle ~= bearingAngleFromTrackObj
                }
            }
        }
        return contains
    }
    
    /**
     It will calculate distance in meter between source location and destination location.
     @param:sourceLatitude an instance of Double,sourceLongitude an instance of Double,destinationLatitude an instance of Double,destinationLongitude an instance of Double
     @return Double
     */
    func calculateDistanceBetweenTwoLocationWithSourceLat1(sourceLatitude:Double,sourceLongitude:Double,destinationLatitude:Double,destinationLongitude:Double) -> Double {
        let locA:CLLocation = CLLocation.init(latitude: sourceLatitude, longitude: sourceLongitude)
        let locB:CLLocation = CLLocation.init(latitude: destinationLatitude, longitude: destinationLongitude)
        let distance:CLLocationDistance = locA.distance(from: locB)
        return distance
    }
    
    func creatGPX(trackPointArray : [CLLocation]) -> Bool {
        let root = GPXRoot(creator: "TrackNinja")
        var trackpoints = [GPXTrackPoint]()
        
        for cords in trackPointArray{
            let yourLatitudeHere: CLLocationDegrees = cords.coordinate.latitude
            let yourLongitudeHere: CLLocationDegrees = cords.coordinate.longitude
            let trackpoint = GPXTrackPoint(latitude: yourLatitudeHere, longitude: yourLongitudeHere)
            trackpoint.time = Date() // set time to current date
            trackpoints.append(trackpoint)
        }
        
        let track = GPXTrack()                          // inits a track
        let tracksegment = GPXTrackSegment()            // inits a tracksegment
        tracksegment.add(trackpoints: trackpoints)      // adds an array of trackpoints to a track segment
        track.add(trackSegment: tracksegment)           // adds a track segment to a track
        root.add(track: track)                          // adds a track
                
        do {
            let path = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            try root.outputToFile(saveAt: path, fileName: "TrackNinjaGPX")
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    func getGPXFile() -> String {
        let fileManager = FileManager.default
        let gpxPath = (self.getDirectoryPath() as NSString).appendingPathComponent("TrackNinjaGPX.gpx")
        
        if fileManager.fileExists(atPath: gpxPath){
//            print(gpxPath)
            return gpxPath
        } else {
            return ""
        }
    }
    
    func getDirectoryPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0];
        return documentsDirectory
    }
    
    //MARK:- FIND DISTANCES OF THREE COORDINATES TO CALCULATE ANGLE
    func isVehicleTurning(points: [CLLocation]) -> Bool {
        let cordinateA = points[0]
        let cordinateB = points[1]
        let cordinateC = points[2]
        
        let distanceAB = cordinateA.distance(from: cordinateB)
        let distanceBC = cordinateB.distance(from: cordinateC)
        let distanceAC = cordinateC.distance(from: cordinateA)
        
        var distanceArray = [CLLocationDistance]()
        distanceArray.append(distanceAB)
        distanceArray.append(distanceBC)
        distanceArray.append(distanceAC)
        return (self.getAngleOfTriangle(distances: distanceArray, turnCordinate: cordinateB))
    }
    
    //MARK:- CALCULATE ANGLE OF TRIANGLE
    func getAngleOfTriangle(distances: [CLLocationDistance], turnCordinate: CLLocation) -> Bool {
        let distanceA = distances[0]
        let distanceB = distances[1]
        let distanceC = distances[2]
        
        let calculateAngle = (pow(distanceA, 2) + pow(distanceB, 2) - pow(distanceC, 2)) / (2*distanceA*distanceB)
        let inverseCos = acos(calculateAngle)
        let turnAngle = Bearing.shared.radiansToDegrees(radians: inverseCos)
        print(turnAngle)
        if turnAngle < 145.0{
            return true
        } else {
            return false
        }
    }
    
    //MARK:- CONVERT KMPH INTO MPS
    func convertToMps(kmphSpeed: Double) -> Double{
        var speedInMps = Double()
        speedInMps = Double((kmphSpeed*5)/18)
        return speedInMps
    }
    
    //MARK:- CONVERT MPS INTO KMPH
    func convertToKmph(mpsSpeed: Double) -> Double{
        var speedInKmph = Double()
        speedInKmph = Double((mpsSpeed)*3.6)
        return speedInKmph
    }
    
    /**
     This function will reset all values once session is finished.
     @param: isDriveViewDisappeared an instance of Bool
     */
    func resetAllValues(isDriveViewDisappeared:Bool)  {
        self.previousLocation = nil
        self.currentLapNumber = 1
        self.isLapStarted = false
        if isDriveViewDisappeared == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.shouldDisableMotion = false
            }
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    /**
     This function will disable motion updates.
     @param: notification an instance of Notification
     */
    @objc func stopGettingMotionUpdatesNotification(notification:Notification) {
        self.shouldDisableMotion = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
