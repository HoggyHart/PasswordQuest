//
//  WeekTransformer.swift
//  PQPrototype
//
//  Created by William Hart on 31/01/2026.
//

import Foundation

@objc(NSWeekTransformer)
class NSWeekTransformer: ValueTransformer{
    
    override class func allowsReverseTransformation() -> Bool {
           true
       }

       override class func transformedValueClass() -> AnyClass {
           NSData.self
       }
    
    
    //transform usable Range into NSData for DB
    override public func transformedValue(_ value: Any?) -> Any? {
            guard let range = value as? NSWeek else { return nil }
            
            do {
                
                let data = try NSKeyedArchiver.archivedData(withRootObject: range, requiringSecureCoding: false)
                return data
            } catch {
                assertionFailure("Failed to transform `Week` to `Data`")
                return nil
            }
        }
    //can read AND write? or ONLY write?
    override public func reverseTransformedValue(_ value: Any?) -> Any? {
            guard let data = value as? NSData else { return nil }
            
            do {
                return try NSKeyedUnarchiver.unarchivedObject(ofClass: NSWeek.self, from: data as Data)
            } catch {
                return NSWeek(week: Week(rawValue: 8))
                //assertionFailure("Failed to transform `Data` to `ScheduleTypeInfo`")
               //xs return nil
            }
        }
}
