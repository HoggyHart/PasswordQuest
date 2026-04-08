//
//  MyJson.swift
//  PQPrototype
//
//  Created by William Hart on 07/04/2026.
//

import Foundation

struct MyJson{
    static func toJson(_ bool: Bool) -> String{
        return bool ? "true" : "false"
    }
}
