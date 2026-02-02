//
//  DateCompare.swift
//  PQPrototype
//
//  Created by William Hart on 31/01/2026.
//

import Foundation

extension Date{
    func equals(date2: Date) -> Bool{
        return self.timeIntervalSince1970 == date2.timeIntervalSince1970
    }
}
