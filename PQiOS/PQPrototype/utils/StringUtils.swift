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

extension Double {
    func truncate(places : Int)-> Double {
        return Double(floor(pow(10.0, Double(places)) * self)/pow(10.0, Double(places)))
    }
    func format(sigFigs: Int) -> String{
        let nf = NumberFormatter()
        nf.roundingMode = .up
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = sigFigs
        return nf.string(for: self) ?? "ErrNo"
    }
}

extension Float {
    func truncate(places : Int)-> Float {
        return Float(floor(pow(10.0, Float(places)) * self)/pow(10.0, Float(places)))
    }
    func format(sigFigs: Int) -> String{
        let nf = NumberFormatter()
        nf.roundingMode = .up
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = sigFigs
        return nf.string(for: self) ?? "ErrNo"
    }
    
}

