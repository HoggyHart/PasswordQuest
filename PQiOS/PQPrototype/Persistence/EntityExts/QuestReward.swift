//
//  QuestReward.swift
//  PQPrototype
//
//  Created by William Hart on 11/02/2026.
//

import Foundation
import CoreData

extension QuestReward{
    var keyType: QuestKeyType{
        get {
            return QuestKeyType(rawValue: self.rawType)!
        }
        set {
            self.rawType = Int16(newValue.rawValue)
        }
    }
}

extension QuestReward{
    static public func generateStandardKey(quest: Quest) -> QuestReward{
        let key = QuestReward(context: quest.managedObjectContext!)
        key.key = quest.questUUID!
        key.questComplete = quest.tasksComplete()
        key.obtainmentDate = Date.now
        key.scheduled = quest.getCurrentScheduler() != nil
        key.keyType = key.questComplete ? QuestKeyType.complete : QuestKeyType.failed
        key.questWasLocked = quest.locked
        quest.addToRewards(key)
        return key
    }
    static public func generateNullifyKey(quest:Quest) -> QuestReward{
        let key = QuestReward(context: quest.managedObjectContext!)
        key.key = quest.questUUID!
        key.questComplete = quest.tasksComplete() //relevant to ignore obtainmentDate, if the quest was complete when deleted then theres no reason to assume foul play -> do not punish user when nullify key is redeemed
        key.obtainmentDate = Date.now //used to determine if the quest was edited pre-schedule (fine) or during schedule (cheating)
        key.scheduled = quest.getCurrentScheduler() != nil //same as last one //not sure if necessary? this info can be inferred by obtainmentDate
        key.keyType = QuestKeyType.nullify
        key.questWasLocked = quest.locked
        quest.addToRewards(key)
        return key
    }
    
    func toJson() -> String{
        var data = "{\n"
        data.append("\"questUUID\" : \"" + key!.uuidString + "\",\n")
        data.append("\"completedOnTime\" : \"" + MyJson.toJson(self.questComplete) + "\",\n")
        data.append("\"obtainmentDate\" : \"" + self.obtainmentDate!.formatted(date: .numeric, time: .standard) + "\",\n")
        data.append("\"scheduled\" : \"" + MyJson.toJson(self.scheduled) + "\",\n")
        data.append("\"type\" : \"" + self.keyType.name + "\"\n") //Not yet implemented. type could be nullify (in case of quest deletion / uuid change
        data.append("\"questLocked\" : \"" +  MyJson.toJson(self.questWasLocked) + "\"\n")
        data.append("}")
        return data
    }
}
