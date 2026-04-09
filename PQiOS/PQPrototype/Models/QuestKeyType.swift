//
//  QuestKeyType.swift
//  PQPrototype
//
//  Created by William Hart on 07/04/2026.
//

import Foundation

public enum QuestKeyType{
    case complete
    case failed
    case nullify //when received, checked against obtainmentDate and scheduled time to determine if edited to cheat at all
    case admin
    
    case defaulT
}

public class NSQuestKeyType: NSObject, NSSecureCoding{
    public static var supportsSecureCoding: Bool = true
    
    public var keyType: QuestKeyType
    
    public func encode(with coder: NSCoder) {
        coder.encode(keyType, forKey: "keyType")
    }
    public required init?(coder: NSCoder) {
        keyType = coder.decodeObject(forKey: "keyType") as? QuestKeyType ?? QuestKeyType.nullify
    }
    
    init(keyType: QuestKeyType){
        self.keyType = keyType
    }
    
    
}
