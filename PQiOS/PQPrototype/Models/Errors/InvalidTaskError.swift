//
//  InvalidTaskError.swift
//  PQPrototype
//
//  Created by William Hart on 18/10/2026.
//

import Foundation

extension String{
    init(_ err: Error){
        self.init()
        self = "\(err)"
    }
}

class InvalidTaskError: Error, CustomStringConvertible{
    let task: String
    let invalidAttribute: String
    init(task: String, invalidAttribute: String) {
        self.task = task
        self.invalidAttribute = invalidAttribute
    }
    
    public var description: String { return "\(task) is invalid: \(invalidAttribute)" }
}
