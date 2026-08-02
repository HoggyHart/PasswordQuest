//
//  QuestKey.swift
//  PQPrototype
//
//  Created by William Hart on 11/02/2026.
//

import Foundation
import CoreData

extension QuestKey{
    var keyType: QuestKeyType{
        get {
            return QuestKeyType(rawValue: self.rawType)!
        }
        set {
            self.rawType = Int16(newValue.rawValue)
        }
    }
}

extension QuestKey{
    static public func generateKey(quest: Quest) -> QuestKey{
        let key = QuestKey(context: quest.managedObjectContext!)
        key.key = quest.questUUID!
        key.obtainmentDate = Date.now
        key.scheduled = quest.getCurrentScheduler()?.scheduleUUID
        key.keyType = quest.tasksComplete() ? QuestKeyType.complete : QuestKeyType.failed
        key.questWasLocked = quest.locked
        quest.addToRewards(key)
        return key
    }
    
    static public func generateAIOKey(context: NSManagedObjectContext) -> QuestKey{
        let key = QuestKey(context: context)
        key.obtainmentDate = Date.now
        key.keyType = QuestKeyType.admin
        return key
    }
    
    func toJson() -> String{
        var data = "{\n"
        data.append("\"questUUID\" : \"" + (key?.uuidString ?? "0") + "\",\n")
        data.append("\"obtainmentDate\" : \"" + self.obtainmentDate!.formatted(date: .numeric, time: .standard) + "\",\n")
        data.append("\"scheduler\" : \"" + (self.scheduled?.uuidString ?? "0") + "\",\n")
        data.append("\"type\" : \"" + self.keyType.name + "\",\n") //Not yet implemented. type could be nullify (in case of quest deletion / uuid change
        data.append("\"questLocked\" : \"" +  MyJson.toJson(self.questWasLocked) + "\"\n")
        data.append("}")
        return data
    }
}
