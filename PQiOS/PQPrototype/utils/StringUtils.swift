//
//  StringUtils.swift
//  PQPrototype
//
//  Created by William Hart on 15/02/2026.
//

import Foundation

struct StringUtils{
    static func firstLetterOfString(str: String) -> Substring{
        return str[..<str.index(str.startIndex, offsetBy: 1)]
    }
}
