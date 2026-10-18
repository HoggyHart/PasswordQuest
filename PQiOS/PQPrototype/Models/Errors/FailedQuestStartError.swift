//
//  FailedQuestStartError.swift
//  PQPrototype
//
//  Created by William Hart on 18/10/2026.
//

import Foundation

class FailedQuestStartError: Error, CustomStringConvertible{
    let reasons: String
    init(reasons: String) {
        self.reasons = reasons
    }
    
    public var description: String { return "Quest Failed To Start: \(reasons)" }
}
