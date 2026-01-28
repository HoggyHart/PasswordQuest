//
//  ScheduleTypeInfo.swift
//  PQPrototype
//
//  Created by William Hart on 11/12/2025.
//

import Foundation

public class Week: OptionSet{
    public let rawValue: Int32
    required public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    func toBitSetString() -> String{
        var str = ""
        for i in 0..<7{
            str.append(self.contains(.Element(rawValue: 1<<i)) ? "1" : "0")
        }
        return str
    }

    static let daysOfTheWeek: [String] = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
    
    static let monday    = Week(rawValue: 1 << 0)
    static let tuesday   = Week(rawValue: 1 << 1)
    static let wednesday = Week(rawValue: 1 << 2)
    static let thursday  = Week(rawValue: 1 << 3)
    static let friday    = Week(rawValue: 1 << 4)
    static let saturday  = Week(rawValue: 1 << 5)
    static let sunday    = Week(rawValue: 1 << 6)


    static let everyday: Week = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    static let weekdays: Week = [.monday, .tuesday, .wednesday, .thursday, .friday]
    static let weekends: Week = [.saturday, .sunday]
}

public class ScheduleTypeInfo: NSObject, NSSecureCoding{
    public static var supportsSecureCoding: Bool = true
    
    public func encode(with coder: NSCoder) {
        coder.encode(everyXDays, forKey: "everyXDays")
        coder.encode(XDayDelay, forKey: "XDayDelay")
        coder.encode(scheduledDays.rawValue, forKey: "scheduledDays")
    }
    
    required public init?(coder: NSCoder) {
        everyXDays = coder.decodeBool(forKey: "everyXDays")
        XDayDelay = coder.decodeInteger(forKey: "XDayDelay")
        scheduledDays = Week(rawValue:coder.decodeInt32(forKey: "scheduledDays"))
    }
    
    init(scheduledDays: Week){
        self.everyXDays = false
        self.scheduledDays = scheduledDays
    }
    
    init(frequency: Int){
        everyXDays = true
        self.XDayDelay = frequency
    }
    var everyXDays: Bool
    var XDayDelay: Int = 1
    var scheduledDays: Week = .everyday
}
