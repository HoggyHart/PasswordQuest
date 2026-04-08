//
//  NSQuestKeyTypeTransformer.swift
//  PQPrototype
//
//  Created by William Hart on 07/04/2026.
//

import Foundation

@objc(NSQuestKeyTypeTransformer)
class NSQuestKeyTypeTransformer: ValueTransformer{
    override class func allowsReverseTransformation() -> Bool {
        true
    }
    override class func transformedValueClass() -> AnyClass {
        NSData.self
    }
    
    
    //transform usable Range into NSData for DB
    override public func transformedValue(_ value: Any?) -> Any? {
            guard let range = value as? NSQuestKeyType else { return nil }
            
            do {
                
                let data = try NSKeyedArchiver.archivedData(withRootObject: range, requiringSecureCoding: false)
                return data
            } catch {
                assertionFailure("Failed to transform `NSQuestKeyType` to `Data`")
                return nil
            }
        }
    //can read AND write? or ONLY write?
    override public func reverseTransformedValue(_ value: Any?) -> Any? {
            guard let data = value as? NSData else { return nil }
            
            do {
                return try NSKeyedUnarchiver.unarchivedObject(ofClass: NSQuestKeyType.self, from: data as Data)
            } catch {
                return NSQuestKeyType(keyType: QuestKeyType.defaulT)
                //assertionFailure("Failed to transform `Data` to `ScheduleTypeInfo`")
               //xs return nil
            }
        }
}
