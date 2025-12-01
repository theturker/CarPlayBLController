import Foundation
import SharedLedController

extension KotlinByteArray {
    func toData() -> Data {
        let size = self.size
        var bytes = [UInt8](repeating: 0, count: Int(size))
        for i in 0..<size {
            let kotlinByte = self.get(index: i)
            // Kotlin Byte is signed (-128 to 127), convert to UInt8 (0 to 255)
            // KotlinByteArray.get() returns NSNumber, get int8Value and convert to UInt8
            // KotlinByteArray.get() returns NSNumber, get int8Value and convert to UInt8
            let nsNumber = kotlinByte as! NSNumber
            let int8Value = nsNumber.int8Value
            bytes[Int(i)] = UInt8(bitPattern: int8Value)
        }
        return Data(bytes)
    }
}

