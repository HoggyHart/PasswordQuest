//
//  NotImplementedError.swift
//  PQPrototype
//
//  Created by William Hart on 18/10/2026.
//

import Foundation

class NotImplementedError: Error, CustomStringConvertible{
    var description: String { return "Function Not Implemented" }
}
