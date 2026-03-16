//
//  StringUtils.swift
//  PQPrototype
//
//  Created by William Hart on 15/02/2026.
//

import Foundation

struct StringUtils{
    static func firstXLettersOfString(str: String, x: Int, trailingEllipse: Bool = false) -> Substring{
        if str.count<x{ return str[..<str.endIndex] }
        return str[..<str.index(str.startIndex, offsetBy: x)] + (trailingEllipse ? "..." : "")
    }
}
