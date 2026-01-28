import Foundation
import CoreLocation

@objc(CLCircularRegion)
class CLCircularRegionTransformer: ValueTransformer{
    //transform usable Range into NSData for DB
    override public func transformedValue(_ value: Any?) -> Any? {
            guard let range = value as? CLCircularRegion else { return nil }
            
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: range, requiringSecureCoding: false)
                return data
            } catch {
                assertionFailure("Failed to transform `Test` to `CLCircularRegion`")
                return nil
            }
        }
    //can read AND write? or ONLY write?
    override public func reverseTransformedValue(_ value: Any?) -> Any? {
            guard let data = value as? NSData else { return nil }
            
            do {
                let range = try NSKeyedUnarchiver.unarchivedObject(ofClass: CLCircularRegion.self, from: data as Data)
                return range
            } catch {
                assertionFailure("Failed to transform `Data` to `CLCircularRegion`")
                return nil
            }
        }
}
