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
    case edited
    case cancelled //for delays + legitimate early ends
    case deleted //for legit and illegitimate deletions, calculated using obtainment date //Fate TBD, could be replaced with cancelled and may be pointless if I find a way to prevent active quests from being deleted
    case admin
    
    case none
    
    public var name: String {
        "\(self)".capitalized
    }
}
