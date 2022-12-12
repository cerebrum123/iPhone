import Foundation

class Vector3D: NSObject {
    
    var x:Double = 0
    var y:Double = 0
    var z:Double = 0
    var vector3DObject:(Double,Double,Double) = (0,0,0)
    static let sharedObject:Vector3D = Vector3D()
   
    /**
     Convert degrees into radians.
     @param:x an instance of Double
     @return : Double value
     */
    func degreeToRadians(x:Double) -> Double{
        return (.pi * x / 180.0)
    }
    
    /**
     Convert radians To Degrees.
     @param:x an instance of Double
     @return : Double value
     */
    func radiansToDegrees(x:Double) -> Double{
        return (x * 180.0 / .pi)
    }
    
    /**
     Init Vector3D object with x, y and z.
     @param:x an instance of Double,y an instance of Double,z an instance of Double
     @return : an instance of Vector3D
     */
    func initWith(x:Double,y:Double,z:Double) -> Vector3D {
        
        let vector3D:Vector3D = Vector3D()
        vector3D.x = x
        vector3D.y = y
        vector3D.z = z
        return vector3D
    }
    
    /**
     Convert latitude and longitude to Vector3D object.
     @param:latitude an instance of Double,longitude an instance of Double
     @return : an instance of Vector3D
     */
    func toVector(latitude:Double,longitude:Double) -> Vector3D {
        var responseConvertToVector:(Double,Double,Double) = (0,0,0)
        
        let φ:Double = self.degreeToRadians(x: latitude)
        let λ:Double = self.degreeToRadians(x: longitude)
        responseConvertToVector.0 = cos(φ)*cos(λ)
        responseConvertToVector.1 = cos(φ)*sin(λ)
        responseConvertToVector.2 = sin(φ)
        return self.initWith(x: responseConvertToVector.0, y: responseConvertToVector.1, z: responseConvertToVector.2)
    }
    
    /**
     Add two vector objects.
     @param:vector an instance of Vector3D which will be added to current vector
     @return : an instance of Vector3D
     */
    func addVectors(vector:Vector3D) -> Vector3D{
        return self.initWith(x:(self.x+vector.x), y: (self.y+vector.y), z: (self.z+vector.z))
    }
    
    /**
     Cross product of two vector objects.
     @param:vector an instance of Vector3D
     @return : an instance of Vector3D
     */
    func crossProductVectorVector(vector:Vector3D)-> Vector3D {
        var responseCrossProduct:(Double,Double,Double) = (0,0,0)
        responseCrossProduct.0 = self.y * vector.z - self.z * vector.y;
        responseCrossProduct.1 = self.z * vector.x - self.x * vector.z;
        responseCrossProduct.2 = self.x * vector.y - self.y * vector.x;
        return self.initWith(x: responseCrossProduct.0, y: responseCrossProduct.1, z: responseCrossProduct.2)
    }
    
    /**
     Dot product of two vector objects.
     @param:vector an instance of Vector3D
     @return : an instance of Vector3D
     */
    func dot(vector:Vector3D) -> Double{
        return self.x * vector.x + self.y * vector.y + self.z * vector.z;
    }
    
    /**
     Convert current selected Vector3D object into lat long.
     @return : an instance of Tuple(Double,Double)
     */
    func toLatLong() -> (Double,Double) {
      
        let φ:Double = atan2(self.z, ((self.x*self.x) + (self.y*self.y)).squareRoot())
        let λ:Double = atan2(self.y, self.x)
        return (self.radiansToDegrees(x: φ),self.radiansToDegrees(x: λ))
    }
}
