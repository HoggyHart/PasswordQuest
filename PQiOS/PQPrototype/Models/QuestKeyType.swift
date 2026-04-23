//
//  QuestKeyType.swift
//  PQPrototype
//
//  Created by William Hart on 07/04/2026.
//

import Foundation

public enum QuestKeyType: Int16, Identifiable, CaseIterable, Codable{
    public var id: Self { self}
    
    case complete
    case failed
    case nullify //when received, checked against obtainmentDate and scheduled time to determine if edited to cheat at all
    case admin
    
    case none
    
    public var name: String {
        "\(self)".capitalized
    }
}
