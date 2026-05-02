//
//  ScheduleTypeInfo.swift
//  PQPrototype
//
//  Created by William Hart on 11/12/2025.
//

import Foundation

public class Week: OptionSet{

    
    public let rawValue: Int16
    required public init(rawValue: Int16) {
        self.rawValue = rawValue
    }
    
    //returns copy of object with val toggled since otherwise it churns out "immutable value" nonsense
    ///obj: Week to affect
    ///day: day to toggle, should be passed in as .monday / .tuesday / 1<<2
    ///Returns copy of object with given day toggled
    static func toggle(obj: Week, day: Int16) -> Week {
        if obj.contains(.Element(rawValue: day)) {
            var copy = obj
            copy.remove(.Element(rawValue: day))
            return copy
        }
        else {
            var copy = obj
            copy.insert(.Element(rawValue: day))
            return copy
        }
    }
    static let daysOfTheWeek: [String] = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    
    static let sunday    = Week(rawValue: 1 << 0)
    static let monday    = Week(rawValue: 1 << 1)
    static let tuesday   = Week(rawValue: 1 << 2)
    static let wednesday = Week(rawValue: 1 << 3)
    static let thursday  = Week(rawValue: 1 << 4)
    static let friday    = Week(rawValue: 1 << 5)
    static let saturday  = Week(rawValue: 1 << 6)

    static let everyday: Week = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
    static let weekdays: Week = [.monday, .tuesday, .wednesday, .thursday, .friday]
    static let weekends: Week = [.saturday, .sunday]
}
